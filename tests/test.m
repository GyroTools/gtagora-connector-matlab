function test(server, api_key)

% this test only fetches data and does not modify Agora
agora = Agora.create(server, api_key);

projects = agora.get_projects();
project = agora.get_project(projects(2).id);
project.get_hosts();
project2 = agora.get_project(projects(2).name);
project.search('test');
project.search('test', 'dataset');
myagora = agora.get_myagora();
root_folder = project.get_root_folder();
exams = myagora.get_exams();
members = project.get_members();
users = agora.get_users();
folder = agora.get_folder(root_folder.id);
subfolders = root_folder.get_folders();
my_subfolder = folder.get_folder(subfolders(1).name);
new_or_existing_folder = root_folder.get_or_create(subfolders(1).name);
items = folder.get_items();
exam = agora.get_exam(exams(1).id);
series = exam.get_series();
datasets = series(1).get_datasets();
datasets = exam.get_datasets();
series = agora.get_series(series(1).id);
dataset = agora.get_dataset(datasets(1).id);
tags = agora.get_tags();
tag1 = agora.get_tag(tags(1).id);
tag2 = agora.get_tag(tags(1).label);
results = agora.search('test', 'study');
