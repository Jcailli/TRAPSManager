-- SERVER SOCKETS POUR TRAPS
dofile('./interface/uty.lua');
dofile('./interface/interface.lua');
dofile('./interface/device.lua');

myServer = nil; -- Server de Socket

function Alert(txt)
	app.GetAuiMessage():AddLine(txt);
end

function Warning(txt)
	app.GetAuiMessage():AddLineWarning(txt);
end

function Error(txt)
	app.GetAuiMessage():AddLineError(txt);
end

-- Information : Numéro de Version, Nom, Interface
function device.GetInformation()
	return { version = 1.2, name = 'TRAPS', class = 'network' };
end	

-- Configuration du Device
function device.OnConfiguration(node)
	local dlg = wnd.CreateDialog(wndFlags.New()
		.Style(wndStyle.DEFAULT_DIALOG)
		.Icon("./res/32x32_tools.png")
		.Label("Configuration TRAPS")
		.Size(200,200)
	);
	
	-- Creation des controles 
	local labelPort = wnd.CreateStaticText(wndFlags.New().Parent(dlg).Label("Port").Style(wndStyle.ALIGN_RIGHT));
	local port = wnd.CreateTextCtrl(wndFlags.New().Parent(dlg).Value(node:GetAttribute('port', '7012')));
	
	local tb = wnd.CreateToolBar(wndFlags.New().Parent(dlg).Style(wndStyle.DEFAULT_TOOLBAR+wndStyle.TB_TEXT));
	local btnSave = tb:AddTool("Enregistrer", "./res/32x32_save.png");
	tb:AddStretchableSpace();
	local btnExit = tb:AddTool("Quitter", "./res/32x32_exit.png");
	tb:Realize();
	
	-- Layout
	local spacing = 4;
	local group = 0;
	local layoutFlags = wndLayoutFlags.New().Group(group).Height(port:GetSize().height).LeftSpacing(spacing).TopSpacing(spacing);

	-- Port
	dlg:AddLayout(labelPort, layoutFlags.Width(labelPort:GetSize().width,0));
	dlg:AddLayout(port, layoutFlags.Width(0,1).RightSpacing(spacing));

	-- Toolbar (Enregistrer & Quitter)
	group = group+1;
	layoutFlags.Group(group).CursorNewLine().RightSpacing(0).LeftSpacing(0);
	dlg:AddLayout(tb, layoutFlags.Width(0,1).Height(48));

	function OnExit(evt)
		dlg:EndModal();
	end

	function OnSave(evt)
		node:DeleteAttribute('port');
		node:AddAttribute('port', port:GetValue());
		app.SaveConfigXML();
		dlg:EndModal();
	end

	-- Bind
	dlg:Bind(eventType.MENU, OnExit, btnExit);
	dlg:Bind(eventType.MENU, OnSave, btnSave);

	-- Affichage Modal
	dlg:Fit();
	dlg:ShowModal();
end

	if node ~= nil then
		trinum.plateforme_depart = node:GetAttribute('plateforme_depart', 'BAS');
	end


-- Ouverture
function device.OnInit(params, node)

	-- Appel OnInit Metatable
	mt_device.OnInit(params);

	local port = 7012;
	if node ~= nil then
		port = tonumber(node:GetAttribute('port', '7012'));
	end

	local address = app.GetCurrentIPAddress();
	
	-- Creation du Server de Socket "TRAPS"
	local mainFrame = app.GetAuiFrame();
	
	myServer = socketServer.Open(mainFrame, address, port);
	mainFrame:Bind(eventType.SOCKET, OnSockServer, myServer:GetId());
	Alert("TRAPS: demarrage serveur "..address..':'..port);
		
end

-- Fermeture
function device.OnClose()
	if myServer ~= nil then
		myServer:Close();
	end

	-- Appel OnClose Metatable
	mt_device.OnClose();
end

function OnSockServer(evt)
	local sockEvent = evt:GetSocketEvent();
	
	if sockEvent == socketNotify.CONNECTION then
		-- CONNECTION
		local sockNew = myServer:Accept();
		if sockNew ~= nil then
			if myServer:AddClient(sockNew) then
				local tPeer = sockNew:GetPeer();
				Alert("TRAPS: ecoute client "..tPeer.ip..':'..tPeer.port);
				return
			end
		end
	elseif sockEvent == socketNotify.LOST then
		-- LOST
		Warning('TRAPS: Client deconnecte');
	elseif sockEvent == socketNotify.INPUT then
		-- INPUT
		myServer:ReadToCircularBuffer(evt:GetSocket());
		local cb = myServer:GetCircularBuffer(evt:GetSocket());
		-- Lecture des Packets 
		while (ReadPacket(cb, evt:GetSocket())) do end
	else
		-- ???
		Error("TRAPS: "..tostring(sockEvent));
	end
end

function ReadPacket(cb)
	local cr = cb:Find(CR);	-- Recherche CR = caractère fin de Trame
	if cr == -1 then return false end 	-- On peut stopper la recherche

	local rawBytes = cb:ReadByte(cr);
	local line = utyPacketString(rawBytes, 1, cr)
	local tab = string.utySplit(line,' ')
	if #tab >= 5 and tab[1]=="penalty" then
		local bib = tonumber(tab[2])
		local gate = tonumber(tab[3])
		local boat = tonumber(tab[4])
		local penalty = tonumber(tab[5])
		Alert("TRAPS: dossard "..bib.." porte "..gate.." penalite "..penalty)
		AddPenalty(bib, gate, boat, penalty);
	elseif #tab >= 3 and tab[1]=="chrono" then
		local bib = tonumber(tab[2])
		local chrono = tonumber(tab[3])
		Alert("TRAPS: dossard "..bib.." chrono "..chrono)
		AddTime(bib, chrono)
	elseif #tab >= 3 and tab[1]=="start" then
		local bib = tonumber(tab[2])
		local chrono = tonumber(tab[3])
		Alert("TRAPS: dossard "..bib.." start "..chrono)
		AddTimePassage(bib, chrono, 0)	
	elseif #tab >= 3 and tab[1]=="finish" then
		local bib = tonumber(tab[2])
		local chrono = tonumber(tab[3])
		Alert("TRAPS: dossard "..bib.." finish "..chrono)
		AddTimePassage(bib, chrono, -1)
	elseif #tab >= 1 and tab[1]=="list" then
		SendBibList()
	else
		Warning("Commande inconnue: "..line)
	end	
	return true;	-- il faut poursuivre la recherche	
end

-- Envoi liste dossards (fenêtre de gestion) vers TRAPSManager
-- Format: bib <numero> <categorie> <horaire>\r ... list_end\r
-- Priorité: <epreuve_load> = catégories sélectionnées dans la vue gestion
function SendBibList()
	local function writeLine(txt)
		if myServer ~= nil then
			myServer:WriteString(txt..string.char(13));
		end
	end

	local function formatSchedule(heureMs)
		if heureMs == nil or heureMs < 0 then return '-' end
		local schedule = app.TimeToString(heureMs, "%2h:%2m:%2s");
		return string.gsub(tostring(schedule), '%s+', '');
	end

	local function sanitize(txt)
		if txt == nil or txt == '' then return '-' end
		return string.gsub(tostring(txt), '%s+', '_');
	end

	local function readBibNumber(t, row)
		local n = t:GetCellInt('Dossard', row, 0);
		if n ~= nil and n > 0 then return n end
		n = tonumber(t:GetCell('Dossard', row));
		if n ~= nil and n > 0 then return n end
		return 0;
	end

	local function readHeureDepart(t, row, codeCourse, codePhase)
		local txt = tostring(codeCourse)..'_'..tostring(codePhase);
		local candidates = {
			'Heure_depart'..txt,
			'Heure_depart',
			'@START_TIME_'..txt..'_1',
			'Heure_depart'..txt..'_1'
		};
		for _, col in ipairs(candidates) do
			local ok, heure = pcall(function() return t:GetCellInt(col, row, -1) end);
			if ok and heure ~= nil and heure >= 0 then
				return heure;
			end
		end
		return -1;
	end

	local function rankingTableFromNotify(notifyName)
		local a, b = app.SendNotify(notifyName);
		if type(a) == 'table' and a.ranking ~= nil then return a.ranking end
		if type(b) == 'table' and b.ranking ~= nil then return b.ranking end
		if a == true and type(b) == 'userdata' then return b end
		if type(a) == 'userdata' then return a end
		return nil;
	end

	local function rowsFromRanking(tRanking, codeCourse, codePhase, sourceLabel)
		if tRanking == nil then return nil end
		local nb = 0;
		pcall(function() nb = tRanking:GetNbRows() or 0 end);
		if nb < 1 then return nil end

		local txt = tostring(codeCourse)..'_'..tostring(codePhase);
		pcall(function() tRanking:OrderBy('Heure_depart'..txt..', Dossard') end);

		local rows = {};
		local categSet = {};
		for i = 0, nb - 1 do
			local bib = readBibNumber(tRanking, i);
			if bib > 0 then
				local categ = sanitize(tRanking:GetCell('Code_categorie', i));
				categSet[categ] = true;
				rows[#rows + 1] = {
					bib = bib,
					categ = categ,
					schedule = formatSchedule(readHeureDepart(tRanking, i, codeCourse, codePhase))
				};
			end
		end
		if #rows < 1 then return nil end

		local categList = {};
		for c, _ in pairs(categSet) do categList[#categList + 1] = c end;
		table.sort(categList);
		Alert("TRAPS: "..sourceLabel.." rows="..tostring(#rows).." categ="..table.concat(categList, ','));
		return rows;
	end

	-- Vue filtrée (catégories cochées en gestion)
	local function loadFromEpreuve(codeCourse, codePhase)
		local tRanking = rankingTableFromNotify('<epreuve_load>');
		return rowsFromRanking(tRanking, codeCourse, codePhase, 'epreuve_load');
	end

	-- Fallback SQL : dossards inscrits sur la course/phase (toute la manche)
	local function loadBibRowsSql(raceInfo, codeCourse, codePhase)
		if raceInfo.tables == nil or raceInfo.tables.Competition == nil then
			return nil, nil, "no_competition_table"
		end
		local tCompetition = raceInfo.tables.Competition;
		local codeCompetition = tCompetition:GetCellInt('Code', 0);
		if codeCompetition == nil or codeCompetition < 1 then
			return nil, nil, "bad_code_competition"
		end

		local ok, db = pcall(function() return sqlBase.Clone() end);
		if not ok or db == nil then
			return nil, nil, "sql_clone_failed"
		end

		local tCourse = db:GetTable('Resultat_Course');
		if tCourse == nil then
			db:Delete();
			return nil, nil, "no_resultat_course"
		end

		local cmdCourse = "Select * From Resultat_Course "..
			"Where Code_competition = "..tostring(codeCompetition)..
			" And Code_course = "..tostring(codeCourse)..
			" And Code_phase = "..tostring(codePhase)..
			" Order By Heure_depart, Code_bateau";
		local okCourse = pcall(function() db:TableLoad(tCourse, cmdCourse) end);
		if not okCourse or (tCourse:GetNbRows() or 0) < 1 then
			db:Delete();
			return nil, nil, "resultat_course_empty"
		end

		local heureByBateau = {};
		local categByBateau = {};
		local bateauList = {};
		for i = 0, tCourse:GetNbRows() - 1 do
			local codeBateau = tostring(tCourse:GetCell('Code_bateau', i) or '');
			if codeBateau ~= '' then
				heureByBateau[codeBateau] = tCourse:GetCellInt('Heure_depart', i, -1);
				local rcCateg = tCourse:GetCell('Code_categorie', i);
				if rcCateg ~= nil and rcCateg ~= '' then
					categByBateau[codeBateau] = sanitize(rcCateg);
				end
				bateauList[#bateauList + 1] = codeBateau;
			end
		end

		local tRes = db:GetTable('Resultat');
		if tRes == nil then
			db:Delete();
			return nil, nil, "no_resultat_table"
		end

		local cmd = "Select * From Resultat Where Code_competition = "..tostring(codeCompetition)..
			" And Dossard Is Not Null And Dossard > 0 Order By Dossard";
		local okLoad = pcall(function() db:TableLoad(tRes, cmd) end);
		if not okLoad then
			db:Delete();
			return nil, nil, "resultat_query_failed"
		end

		local rows = {};
		for i = 0, tRes:GetNbRows() - 1 do
			local codeBateau = tostring(tRes:GetCell('Code_bateau', i) or '');
			if codeBateau ~= '' and heureByBateau[codeBateau] ~= nil then
				local bib = readBibNumber(tRes, i);
				if bib > 0 then
					local categ = categByBateau[codeBateau];
					if categ == nil then
						categ = sanitize(tRes:GetCell('Code_categorie', i));
					end
					rows[#rows + 1] = {
						bib = bib,
						categ = categ,
						schedule = formatSchedule(heureByBateau[codeBateau])
					};
				end
			end
		end

		Alert("TRAPS: sql fallback rows="..tostring(#rows).." (manche complete course/phase)");
		return rows, db, "ok";
	end

	local rcRace, raceInfo = app.SendNotify('<race_load>');
	if rcRace == false or type(raceInfo) ~= 'table' then
		writeLine("list_error race_load");
		Warning("TRAPS: list impossible (race_load)");
		return
	end

	local codeCourse = tonumber(raceInfo.Code_course) or 1;
	local codePhase = tonumber(raceInfo.Code_phase) or 1;

	local rows = loadFromEpreuve(codeCourse, codePhase);
	local source = 'epreuve_load';

	if rows == nil or #rows < 1 then
		local db, status;
		rows, db, status = loadBibRowsSql(raceInfo, codeCourse, codePhase);
		if db ~= nil then db:Delete() end
		source = 'sql';
		if rows == nil then
			writeLine("list_error sql_"..tostring(status));
			Warning("TRAPS: list impossible ("..tostring(status)..")");
			return
		end
	end

	if #rows == 0 then
		writeLine("list_error empty_selection");
		Warning("TRAPS: list vide (aucune categorie selectionnee ?)");
		return
	end

	-- Nb_porte = nombre de portes de la fenetre gestion de course
	local nbPortes = tonumber(raceInfo.Nb_porte) or 0;
	if nbPortes > 0 then
		writeLine("gates "..tostring(nbPortes));
	end

	for i = 1, #rows do
		local r = rows[i];
		writeLine("bib "..tostring(r.bib).." "..r.categ.." "..r.schedule);
	end

	writeLine("list_end "..tostring(#rows));
	Alert("TRAPS: list envoyee ("..tostring(#rows).." dossards via "..source..", portes="..tostring(nbPortes)..")");
end



function AddPenalty(bib, gate, embarcation, penalty)
	app.SendNotify('<penalty_add>',
		{ bib = bib, gate = gate, embarcation = embarcation, penalty = penalty  }
	);
end

function AddTime(bib, chrono)
	app.SendNotify("<bib_time>", 
		{ time = chrono,  passage = -1, bib = bib }
	);
end

function AddTimePassage(bib, chrono, passage)
	app.SendNotify("<passage_add>", 
		{ time = chrono, passage = passage, bib = bib, device = 'TRAPS' }
	);
end
