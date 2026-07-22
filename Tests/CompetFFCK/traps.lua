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
	else
		Warning("Commande inconnue: "..line)
	end	
	return true;	-- il faut poursuivre la recherche	
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
