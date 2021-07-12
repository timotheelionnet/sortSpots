function fh = dispwin(title_msg,txtmsg,varargin)

%displays a message in a popup window
%you can add the handle to a previous message figure to replace it by the
%new one (last optional argument)
%returns the handle to the new figure

%check whether a popup already exists
if numel(varargin)== 0
    create_new_fig = 1;
else
    if ishandle (varargin{1})
        create_new_fig = 0;
    else
        create_new_fig = 1;
    end
end

if create_new_fig == 1
    %create new pop up message figure from scratch
    %calculating the size of the text panel and adjusting the window size
    %accordingly
    nlines = length(txtmsg) / 80;
    NL = sprintf('\n'); %if there are formatted line breaks
    nlines = nlines+numel(strfind(txtmsg,NL));

    txtheight = ceil(nlines) * 1.5 + 0.5;
    panelheight = txtheight + 3;

    %setting the figure up
    fh = figure('Units','characters',...
                      'NumberTitle','off',...
                      'MenuBar','none',...
                      'Toolbar','none',...
                      'Name',title_msg,...
                      'Position',[10 10 90 panelheight],...
                      'Visible','off'); 

    %centering the picture              
    set(fh,'units','normalized');              
    pos = get(fh,'Position');
    set(fh,'Position',[0.5 - pos(3)/2, 0.5 - pos(4)/2 ,pos(3),pos(4)]);

    %text panel
    uicontrol('parent',fh,'Units','characters',...
                'HorizontalAlignment','Center',...
                'Style','text','String',txtmsg,...
                'Tag','textmessage',...
                'Position',[15,1.5,60,txtheight]);  


    set(fh,'Visible','on');
    figure(fh);
    drawnow;
    setappdata(fh,'Lx',pos(3)/90);
    setappdata(fh,'Ly',pos(4)/panelheight);
    
else
    %update size and messages in figure
    nlines = length(txtmsg) / 80;
    NL = sprintf('\n'); %if there are formatted line breaks
    nlines = max(nlines,numel(strfind(txtmsg,NL)));

    txtheight = ceil(nlines) * 1.5 + 0.5;
    panelheight = txtheight + 3;
    
    fh = varargin{1};
    handles = guihandles(fh);
    
    Lx = getappdata(fh,'Lx');
    Ly = getappdata(fh,'Ly');
    WinX = 90*Lx;
    WinY = panelheight*Ly;
    
    %set(fh,'Units','normalized');    
    set(fh,'Position',[0.5 - WinX/2, 0.5 - WinY/2 ,WinX,WinY]);
    set(fh,'Name',title_msg);
    
    %set(handles.textmessage,'Units','characters');
    set(handles.textmessage,'Position',[15,1.5,60,txtheight]);
    set(handles.textmessage,'String',txtmsg);
    figure(fh);
    drawnow;
    
end
end