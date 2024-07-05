# gtagora-connector

gtagora-connector-matlab is a Matlab library to access GyroTools' Agora system.

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

root_folder.upload('/path/to/directory/or/file');
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

Get the members of a project

```matlab
members = project.get_members();
```

Add a new member to the project

```matlab
users = agora.get_users();
project.add_member(users(1), 'scientist');
```

Search within a project

```matlab
project.search('test');
```

Search only for a specific type (datasets in this case)

```matlab
project.search('test', 'dataset');
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

Get all items of a folder. An item could for example be an exam, series or dataset. Please note that the returned items are sorted by their database id. 

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

Get the parents of an object

```matlab
% get parents of a dataset
series = dataset.get_series();      % get series 
exam = dataset.get_exam();          % get exam
patient = dataset.get_patient();    % get patient
folders = dataset.get_folders();	% get the folders which contain the dataset

% get parents of a series
exam = series.get_exam();           % get exam
patient = series.get_patient();     % get patient
folders = series.get_folders();     % get the folders which contain the series

% get parents of an series
exam = agora.get_exam(exam_id);
patient = exam.get_patient();       % get patient
folders = exam.get_folders();       % get the folders which contain the series
```

### Filters

Filters can be used to retrieve objects that meet a certain criteria. They can be applied to different object types such as projects, exams, datasets, and series. 

In order to filter objects we pass one or more filter classes to the get functions as argument (e.g. `get_exams`). Every filter class has a `value` attribute which specifies the criteria to be filtered for and an `operator` which specifies the filter operation, such as `contains`, `startswith` etc. 

You can get all the available filters for an object with:

```matlab
exam_filter_set = agora.get_exam_filters()       % filters for exam
series_filter_set = agora.get_series_filters()   % filters for series
dataset_filter_set = agora.get_dataset_filters() % filters for dataset
```

This returns a map where the key is the field name which is filtered and the value is the filter class. You can get the filter for a specific field with:

```matlab
name_filter = exam_filter_set.get_filter('name');   % gets the filter which filters for the exam name
```

Afterwards you can set a filter operator according to your needs:

```matlab
name_filter.operator = 'startswith';
```

To display a list of all operators call:

```matlab
disp(name_filter.operators)
```

Finally set a filter value and get the objects meeting the filter critera. In this case we would get all studies of a project whose name start with "Study"

```matlab
name_filter.value = 'Study';
project.get_exams(name_filter);
```

Examples:

```matlab
% get all exams of a  project which start with "study" (case insensitive)
project = agora.get_project(project_id);                    % get the project
exam_filter_set = agora.get_exam_filters()                  % get the exam filters
name_filter = exam_filter_set.get_filter('name');           % get the filter for the exam name
name_filter.operator = 'istartswith';                       % set the operator
name_filter.value = 'study';                                % filter for "study"
project.get_exams(name_filter);                             % get the filtered exams


% get all Philips raw datasets of an exam which have "FFE" in the name
exam = agora.get_exam(exam_id);                             % get an exam
types = agora.get_dataset_types();                          % get the dataset types

dataset_filter_set = agora.get_dataset_filters()            % get all filters for the dataset
type_filter = dataset_filter_set.get_filter('type');        % get the filter for the dataset type
type_filter.value = types.PHILIPS_RAW;                      % specify to filter for Philips raw files

name_filter = dataset_filter_set.get_filter('name');        % get the filter for the dataset name
name_filter.operator = 'icontains';                         % specify the operator
name_filter.value = 'ffe';                                  % filter for "ffe"

filters(1) = type_filter;                                   % put both filters in an array
filters(2) = name_filter;
datasets = exam.get_datasets(filters);                      % get the filtered datasets


% get all series of an exam which have "FFE" in the name
series_filter_set = agora.get_series_filters()              % get all filters for a series
name_filter = series_filter_set.get_filter('name');         % get the filter for the series name
name_filter.value = 'ffe';                                  % filter for "ffe" in name
exam.get_series(name_filter);                               % get the filtered series    
```



### Tag Objects

Get all tags the current user has access to:

```matlab
tags = agora.get_tags();
```

Get a tag by id or name:

```matlab
tag1 = agora.get_tag(3);
tag2 = agora.get_tag('good');
```

Tag an agora object:

```matlab
exam = agora.get_exam(12);
series = agora.get_series(24);
dataset = agora.get_dataset(145);
folder = agora.get_folder(15);

tag_instance1 = exam.tag(tag1);
tag_instance2 = series.tag(tag1);
tag_instance3 = dataset.tag(tag1);
tag_instance4 = folder.tag(tag1);
```

Get all objects for a specific tag:

```matlab
% get tags for a project
project_id = 3;
project = agora.get_project(project_id);
tags = project.get_tags();

% get exams, series, datasets, patients for a tag
tag = tags(1);
exams = project.get_exams_for_tag(tag);
series = project.get_series_for_tag(tag);
datasets = project.get_datasets_for_tag(tag);
patients = project.get_patients_for_tag(tag);
```

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

By default, the data from each Study, Series, Dataset, etc., is downloaded to its own subfolder. 
However, it is possible to disable this behavior and download everything into a single flat folder by using the 'flat' option:

```matlab
downloaded_files = series.download(target, 'flat', true);
```

The download can be further customized by filtering the datasets based on their type or by using a regular expression to match the filenames:


```matlab
% filtered by dataset types
t = agora.get_dataset_types();
downloaded_files = series.download(target, 'dataset_types', [t.PHILIPS_RAW, t.PHILIPS_SINFILE]);

% filtered by regex (downloads all files with extension .log)
downloaded_files = series.download(target, 'regex', '\.log');
```



### Import data

Upload a file or directory into a folder

```matlab
folder = agora.get_folder(45);
dir = '/data/images/';
file = '/data/logfile.txt';
folder.upload(dir);
folder.upload(file);
```

### Advanced Upload

The advanced upload functionality creates an upload session for transferring files to Agora. It tracks the upload 
process, enables the users to resume an interrupted upload and ensures data integrity.

To create an upload session use the following syntax:

```matlab
files = {'C:/data/raw/rawfile.raw', 'C:/data/raw/rawfile.lab', 'C:/data/log/logfile.txt'};
progress_file = 'C:/data/progress.json';
target_folder_id = 45;
session = agora.create_upload_session(files, target_folder_id, progress_file);
```

After creating the session start the upload with:

```matlab
session.start()
```

If an upload was interrupted or stopped, the session can be recreated and resumed using the progress_file:

```matlab
session = agora.create_upload_session(progress_file)
session.start()
```

Furthermore, the advanced upload will verify the data integrity of the uploaded files by comparing file hashes. It also waits 
for the data import to finish before returning and checks if all uploaded files are imported successfully. 

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

Get all tasks of a project:

```matlab
project = agora.get_myagora();
tasks = project.get_tasks();
```

Get a task by ID or name

```matlab
task = project.get_task(4);
task = project.get_task('my_task');
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
timeline = task.run(target_folder, 'ds', dataset, 'size', 13);
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
```-->

### Various

Search in the entire Agora

```matlab
results = agora.search('test');
``` 

Search only for a certain type (studies in this case)

```matlab
results = agora.search('test', 'study');
``` 

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

Please make sure to update tests as appropriate.

## License

[MIT](https://choosealicense.com/licenses/mit/)
