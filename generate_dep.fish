#!/bin/fish

# delcare variables
set dep_name
set dep_type
set actual_dep_name
set dep_types "custom" "apt" "pip"
set dep_types_possible_custom_name "apt" "pip"
set script_directory (dirname (status current-filename))
set templates_directory "$script_directory/templates"


# declare functions
function set_dep_name
  # our name of the dependency from script arguments
  set dep_name $argv[1]
  if not test "$dep_name"
    set dep_name (gum input --placeholder "dependency name")
  end
end

function set_dep_type
  # dependency type as given in dep_types
  set dep_type $argv[1]
  if not test "$dep_type"; or not contains $dep_type $dep_types
    set dep_type (gum choose $dep_types)
  end
end

function set_actual_dep_name
  # the actual name of the dependency from script arguments
  set actual_dep_name $argv[1]
  # if not specified as an argument to the script the ask for it
  if not test "$actual_dep_name"
    set actual_dep_name (gum input --placeholder "dependency name (actual apt or pip name), ESC or Enter for the same name as previous")
  end
  # if nothing then simply use the previously given name
  if not test "$actual_dep_name"
    set actual_dep_name $dep_name
  end
end

function update_amz_yaml
  # replace the names with the ones specified by the user
  set new_text (
    cat "$templates_directory/yaml_template_$dep_type" | \
      string replace --all "\$dep_name" "$dep_name" | \
      string replace --all "\$actual_dep_name" "$actual_dep_name"
  )
  
  # update the file
  echo "" >> $script_directory/amz.yaml; and \
  printf '%s\n' $new_text >> $script_directory/amz.yaml
end

function create_rdmanifest
  # new folder + file from template
  mkdir $dep_name; and \
  cat "$templates_directory/rdmanifest_template" >> $script_directory/$dep_name/$dep_name.rdmanifest
end


# run the script

# setting the variables
set_dep_name $argv[1]
if test -z "$dep_name"
  echo "name for the dependency not specified"
  exit
end

set_dep_type $argv[2]
if test -z "$dep_type"
  echo "type for the dependency not specified"
  exit
end
if contains $dep_type $dep_types_possible_custom_name
  set_actual_dep_name $argv[3]
  if test -z "$actual_dep_name"
    echo "actual dependency name not specified"
    exit
  end
end

# update the amz yaml
update_amz_yaml
if test $status -eq 0 
  echo "updated amz.yaml"
else
  echo "failed updating amz.yaml"
  exit
end

# create rdmanifest
if test "$dep_type" = "$dep_types[1]" # if custom
  create_rdmanifest
  if test $status -eq 0
    echo "created $dep_name.rdmanifest"
    echo "now please update the $dep_name.rdmanifest"
  else
    echo "failed creating $dep_name.rdmanifest"
    exit
  end
end
