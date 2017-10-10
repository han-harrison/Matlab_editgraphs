%%Script, Takes all graphs in folder and passes them to a function

fig_files=dir(fullfile(pwd,'\*.fig'));

for i=1:length(fig_files)
   Edit_graphs(fig_files(i).name, 2, 'true', 'false');
end