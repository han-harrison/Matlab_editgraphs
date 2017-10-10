function  [  ] = Edit_graphs(fig_name, save_option, title_var, is_open, is_open_num)
%Function Edit_graphs.m takes the handle of a figure or a saved .fig file, edits it and then
%saves as a .png (and .pdf) in the current folder
%Arguments. 
% fig_name --> Name of the figure (either its saved name if it is saved as a .fig file, 
%or the name you wish to save to as .pdf/.png)
%save_option --> 1 or 2. 
%	1 uses imwrite() which is an inbuilt matlab function (this works well, but is very slow and opens every figure)
%	2 use export_fig() (recommended) which needs to be downloaded separately 
%		export_figs is an excellent used made function which is still maintained and is avaliable on 
%		github: https://github.com/altmany/export_fig
%		as well as on the 
%		mathworks website: https://uk.mathworks.com/matlabcentral/fileexchange/23629-export-fig
%title_var --> "true" or "false"
%	used to specify if this figure should have a title or not (only affects figure that already have titles)
%	"true" formats title to fit style of graph
%	"false" removes title from the graph
%is_open --> "true" or "false"
%	indicates if you want to use the function on a figure that you have open in matlab
%	"true" function operates on open figure specified by variable is_open_var
%	"false" function will open a previously saved figure -> fig_name.fig
%is_open_num --> #number of currently open figure
%	gives the handle of a currently open figure in matlab, only used when is_open = "true"
%	if is_open="false" just add a dummy variable here

    %%Variables needed (load fontsizes, fonts, offset values etc.)
    titleFont=50;
    axisFont=32;
    generalFont = 26;
    
    MyFont = 'Times New Roman';
    MyFontStyle = 'Italic'; %If you don't like italics then set to 'normal' instead
    offsetx = 0.01;
    offsety = 0.01; %for padding axis labels
	
	x0=10; %x0 and y0 for position on screen in units="points"
    y0=10;
    width=850; %width and height are used to set size of figure in units="points"
    height=700;
    
    %%formats fig_name appropriately for use in the rest of this function
    if strcmp(fig_name(end-3:end), '.fig')
        fig_name = fig_name(1:end-4);
    end
	
    %Loads .fig and set handle. Invisibile setting ensures that figure does
    %not open on screen. 
	%Otherwise sets handle to currently open figure - if this is the case the figure is not invisible.
    if strcmp(is_open, 'false')
        h_graph = openfig(fig_name, 'invisible');
    elseif strcmp(is_open, 'true') && ishandle(is_open_num) && strcmp(get(is_open_num, 'type'), 'figure');
        h_graph = figure(is_open_num);
    else
        error('No valid figure selected');
    end
	
	%Sets up handles for editing
    h_plot = findobj(h_graph, 'type', 'ax');
    h_line = findobj(h_graph, 'type', 'line');
    h_leg=findobj(h_graph,'Type','axes','Tag','legend');
    
	%sets properties of graph handles
    set(h_graph,'units','points','position',[x0,y0,width,height]);%size and position
    set(h_graph,'color','w');%set background colour to white
	
	%sets properties of plot handles
    set(h_plot,'box','on', 'linewidth', 1.5, 'Layer', 'top')%axis (inc top and right) box 
    set(h_plot, 'Units', 'points')%units
    set(h_plot, 'XTickMode', 'manual')%stops automatic tickmark resizing - very useful if we have manually set the ticklabels
    set(h_plot, 'YTickMode', 'manual')%for example, when creating a log axis
    set(h_plot, 'FontSize', generalFont, 'FontName', MyFont, 'FontAngle', MyFontStyle);%set the fontsize, font and style
	
	%This following loop pads out the axis slightly to avoid any overlap of the tickmarks
	%This means that the tickmarks are 
	x_spacer_factor = 0.015;
	y_spacer_factor = 0.015;
    for i = 1:length(h_plot)
        if mod(i, 2) == 0
            x_limits = get(h_plot(i), 'xlim');
            y_limits = get(h_plot(i), 'ylim');
            x_ticks = get(h_plot(i), 'Xtick');
            y_ticks = get(h_plot(i), 'Ytick');
            
            x_spacer = (x_limits(2)-x_limits(1))*x_spacer_factor;%0.015;
            y_spacer = (y_limits(2)-y_limits(1))*y_spacer_factor;
            
            set(h_plot(i), 'xlim', [x_limits(1)-x_spacer, x_limits(2)+x_spacer]);
            set(h_plot(i), 'ylim', [y_limits(1)-y_spacer, y_limits(2)+y_spacer]);
        end
        
    end
  
    %%%this section makes title edits as selected (doesn't deal with mtit.m ttitles on subfigures)
    h_title = get(h_plot, 'title');
    for i = 1:length(h_title)
        if strcmp(title_var, 'false')
            set(h_title{i}, 'String', '');
        else
            set(h_title{i}, 'FontSize', titleFont, 'FontName', MyFont, 'FontAngle', 'Italic');
        end
    end
    
    %%this section does the axis label formatting 
    hx = get(h_plot, 'xlabel');
    hy = get(h_plot, 'ylabel');
    for i = 2:length(hx)    
        set(hx{i}, 'FontSize', axisFont, 'FontName', MyFont, 'FontAngle', 'Italic');
        set(hy{i}, 'FontSize', axisFont, 'FontName', MyFont, 'FontAngle', 'Italic');
    end
    
   

   %%%resize errorbars, and control for thickness 
   %%matlab can be a bit flaky on errorbar width, thickness etc. 
   %%This section finds all the error bars in your figure, calculates and appropriate thickness (based on the linewidth) 
   %%%and appropriate width based on the size of the plot and the number of data points. If you resize you may find that the value of 
   %%minimum_errbar_width should be changed as well#
   minimum_errbar_width = 0.02 ;
   %%It also makes the colour of the errorbars slightly darker - which I find makes them more visible. To increase this effect reduce the value of 
   %%colour_factor and to decrease it raise the value of colour_factor. colour_factor must be between 0 and 1. Set to 1 to keep all colours constant, set to 0 to make the
   %%errorbars black
   colour_factor = 0.8;
   for j = 1:length(h_plot)
        h_eb = findobj(h_plot(j), '-property', 'Udata');
        if ~isempty(h_eb)
            ch = get(h_plot(j), 'children');
            xdata_temp = get(ch, 'xdata');
            for k = 1:length(xdata_temp)
                tot_len_temp(i) = length(xdata_temp{i});
            end
            [res, index_max] = max(tot_len_temp);
            span = range(xdata_temp{index_max});
            errorbar_size = span*( minimum_errbar_width + 1/(res*3));
            for i= 1:length(h_eb)
               WidthTemp = get(h_eb(i), 'LineWidth');
               if WidthTemp>8
                   NewThick = WidthTemp-4;
               elseif WidthTemp>4
                   NewThick = WidthTemp-2;
               else
                   NewThick = WidthTemp;
               end
               ColourTemp = get(h_eb(i), 'Color');
               errorbarT(h_eb(i),  errorbar_size, NewThick);
               set(h_eb(i), 'Color', ColourTemp*0.8);
               set(h_eb(i), 'MarkerEdgeColor', ColourTemp);
            end
        end
        h_eb = [];
   end
   
   %%edit legend icons to include linethickness etc. Based on assumption
   %%that the average linethickness of the entire figure is appropriate. Alternative is to set this manually.
   for i = 1:length(h_leg)
        h_children = get(h_leg(i),'children');
        h_leg_lines = findobj(h_children, 'Type', 'Line'); 
        line_width_typical = get(h_line, 'linewidth');
        set(h_leg_lines, 'LineWidth', mean(cell2mat(line_width_typical)));
   end
   
   %%save options - 1. saves as .png in current folder. 2. saves as .png and .pdf in current folder. 
    if save_option ==1
        img_temp = getframe(h_graph);
        imwrite(img_temp.cdata, [fig_name,'.png']); %saves nicely but causes figure to open on screen
    elseif save_option == 2
        export_fig(h_graph, sprintf('%s', fig_name), '-pdf', '-png', '-c[0,0,0,0]' ); %this works, is a little slow, need to download function from github
                                                                                            % To use .eps you need to install ghostscript (to use the function pdftops correctly) 
																							%which I can't do on the machine I am currently working in
    end
    %%In addition, if you were working with an open graph in matlab, it will be saved as a .fig here.
    if strcmp(is_open, 'true')
        saveas(h_graph, fig_name)
    end
end

