# gtagora-connector

gtagora-connector is a python library to access GyroTools' Agora system.

## Installation

Clone the repository and add the cloned directory to Matlab path

## Basic usage

```matlab
server = '<AGORA SERVER>'
api_key = '<YOUR_API_KEY>'

agora = Agora.create(server, api_key);

myagora_project = agora.get_myagora();
root_folder = myagora_project.get_root_folder();
subfolders = root_folder.get_folders();
for i = 1:length(subfolders)
    disp([' - ', subfolders(i).name]);
end

new_folder = root_folder.get_or_create('New Folder');

exams = myagora_project.get_exams();
if ~isempty(exams)
    exam = exams(1);
    series = exam.get_series();
    for i = 1:length(series)
        disp(['Series: ', series(i).name]);

        datasets = series(i).get_datasets();
        for j = 1:length(datasets)
            disp(['    Dataset: ', datasets(j).name]);
            datafiles = datasets(j).get_datafiles();
            for k = 1:length(datafiles)
                disp(['        ', datafiles(k).original_filename]);
            end
        end
    end
end

agora.import_data('/path/to/directroy', new_folder);
```

## Examples

### Create an Agora instance

```matlab
agora = Agora.create('https://your.agora.domain.com', '<YOUR_API_KEY>')
```

The API key can be activated in your Agora profile, and is a random UUID which can be withdrawn or recreated easily.

### Working with projects

Get a list of projects:

```matlab
projects = agora.get_projects();
for i = 1:length(projects)
    disp(projects(i).name);
end
```

Get a project by ID:

```matlab
project = agora.get_project(2);
disp(project.name);
```

Get a project by name:

```matlab
project = agora.get_project('test_project');
```

Get the \"My Agora\" project:

```matlab
myagora = agora.get_myagora();
```

Get root folder of a project

```matlab
project = agora.get_project(2);
root_folder = project.get_root_folder();
```

Get all exams of a project

```matlab
project = agora.get_project(2);
exams = project.get_exams();
```

Empty the trash

```matlab
project = agora.get_project(2);
project.empty_trash();
```

### Working with folders

Get the root folder of the \"My Agora\" project:

```matlab
myagora = agora.get_myagora();
root_folder = myagora.get_root_folder();
```

Get a folder by its ID

```matlab
folder = agora.get_folder(45);
```

Get sub folders

```matlab
subfolders = folder.get_folders();
for i = 1:length(subfolders)
    disp([' - ', subfolders(i).name]);
end
```

Get a subfolder folder by name. None will be returned if the folder does not exist

```matlab
my_folder = folder.get_folder('my_folder')
```

The get_folder function also takes a relative path.

```matlab
my_subfolder = folder.get_folder('my_folder/my_subfolder')
``` 

Create a new folder in the root folder (the new folder object is returned). An exception is thrown if a folder with the same name already exists.

```matlab
new_folder = root_folder.create('TestFolder');
```

Get a folder or create a new one if it does not exist

```matlab
new_or_existing_folder = root_folder.get_or_create('TestFolder');
```

Delete a folder. Delete a folder is recursive. It deletes all items. The delete operation does not follow links.

```matlab
folder.remove()
```

Get all items of a folder. An item could for example be an exam, series or dataset

```matlab
items = folder.get_items();
for i = 1:length(items)
    disp(items(i).content_object.name)
end
```

<!-- Get all exams of a folder. Use the recursive parameter to also get the exams in all subfolders

```matlab
exams = folder.get_exams();
for exam in exams:
    print(f" - {exam}")
``` -->

<!-- Get all datasets of a folder. Use the recursive parameter to also get the exams in all subfolders

```matlab
datasets = folder.get_datasets();
```

Get a dataset by name. None is returned if the dataset does not exist

```matlab
dataset = folder.get_dataset('my_dataset')
```

Get the path of a folder within Agora (breadcrumb)

```matlab
folder = agora.get_folder(45)
breadcrumb = folder.get_breadcrumb()
``` -->

### Working with Agora objects

<!-- Get the list of exams

```matlab
exams = agora.get_exams();
``` -->

Get an exam by ID

```matlab
exam = agora.get_exam(12);
```

<!-- Link the first Exam to the a folder

```matlab
exam_item = exam.link_to_folder(folder.id)
``` -->

<!-- Delete the link of an exam (doesn't delete the Exam itself)

```matlab
exam_item.delete()
``` -->

Get all series of an exam and then all datasets of the first series

```matlab
series = exam.get_series();
datasets = series(1).get_datasets();
```

Get all datasets of an exam

```matlab
datasets = exam.get_datasets();
```

<!-- Get a list of all patients

```matlab
patients = agora.get_patients()
```

Get a patient by ID

```matlab
patient = agora.get_patient(15)
``` -->

Get a series or dataset by ID

```matlab
series = agora.get_series(76);
dataset = agora.get_dataset(158);
```

<!-- ### Tag Objects

Get all tags the current user has access to:

```matlab
tags = agora.get_tags()
```

Get a tag by id or name:

```matlab
tag1 = agora.get_tag(id=3)
tag2 = agora.get_tag(name='good')
```

Tag an agora object:

```matlab
exam = agora.get_exam(12)
series = agora.get_series(24)
dataset = agora.get_dataset(145)
folder = agora.get_folder(15)
patient = agora.get_patient(2)

tag_instance1 = exam.tag(tag1)
tag_instance2 = series.tag(tag1)
tag_instance3 = dataset.tag(tag1)
tag_instance4 = folder.tag(tag1)
tag_instance5 = patient.tag(tag1)
``` -->

### Download data

Download all data from a folder

```matlab
target = '/data/downloads';
downloaded_files = folder.download(target);
```

Exams, series and datasets also have a download function

```matlab
downloaded_files = exam.download(target);
downloaded_files = series.download(target);
downloaded_files = dataset.download(target);
```

### Import data

Upload a directory into a folder

```matlab
folder = agora.get_folder(45)
dir = '/data/images/';
folder.upload(dir)
```

<!-- Upload (and import) a rawfile and add an additional file to the the created series (Agora version > 6.3.0):

In this example a scanner rawfile and a textfile is uploaded. The rawfile will be imported into Agora and a Study and Series
will be created. We can add the additional text file to the created Series by specifying the "relations" attribute in the
upload function. The "relations" attribute is a dictionary whose key is the path to the rawfile and the value is a list
of additional files which will be added to the created series:

```matlab
folder = agora.get_folder(45)

files = [
Path('C:/data/raw/rawfile.raw'),
Path('C:/data/raw/rawfile.lab'),
Path('C:/data/log/logfile.txt'),
]

relations = {
'C:/data/raw/rawfile.raw' : ['C:/data/log/logfile.txt']
}

folder.upload(files, relations=relations)
```

This also works when uploading a whole directory:

```matlab
folder = agora.get_folder(45)

dir = [Path('C:/data/')]

relations = {
'C:/data/raw/rawfile.raw' : ['C:/data/log/logfile.txt']
}

folder.upload(dir, relations=relations)
``` -->

### Working with tasks

Get all tasks visible to the current user:

```matlab
tasks = agora.get_tasks();
```

Get a task by ID

```matlab
project = agora.get_project(2);
tasks = project.get_tasks;
```

**Run a task:**

In this example the task has 2 inputs:

- A dataset with key "ds"
- An integer number with key "size"

The last line in the code sample waits for the task to finish

```matlab
project = agora.get_myagora();
task = project.get_task('my_task');
target_folder = agora.get_folder(24)
dataset = agora.get_dataset(57)
timeline = task.run(folder, 'ds', dataset, 'size', 13);
timeline.join()
```

<!-- alternatively only the ID's of the Agora objects can be given as argument:

```matlab
taskinfo = task.run(target=target_folder, ds=23, size=1024)
```

the syntax to run the task can be printed to the console with the syntax function:

```matlab
task.syntax()
```

Save a task after it has been modified

```matlab
task = agora.get_task(13)
task.name = 'new_name'
task.save()
```

Delete a task

```matlab
task.delete()
```

Export all tasks into a json file

```matlab
agora.export_tasks('<output file>.json')
```

Import tasks from file (Experimental!)

```matlab
agora.import_tasks('<input file>.json')
``` -->

<!-- ### Working with parameters

Get a parameter by name

```matlab
dataset = agora.get_dataset(13)
parameter = dataset.get_parameter('EX_ACQ_echoes')
if not parameter.is_array:
    value = parameter.values[0]
else:
    value = parameter.values
```

Search for parameters

```matlab
dataset = agora.get_dataset(13)
parameters = dataset.search_parameter('EX_ACQ_')
print(f'{len(parameters)} parameters found')
```

### Users and sharing

Get the current user

```matlab
current_user = agora.get_current_user()
```

Get all users

```matlab
users = agora.get_users()
```

Get all user groups

```matlab
users = agora.get_groups()
```

### Various

The members of any Agora object can be printed to the console with the display function

```matlab
exam = agora.get_exam(22)
exam.display()

folder = agora.get_folder(15)
folder.display()
``` -->

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

Please make sure to update tests as appropriate.

## License

[MIT](https://choosealicense.com/licenses/mit/)
