import os

def replace_carriage_return(file_path):
    # Read the contents of the file
    with open(file_path, 'r', encoding='mac_roman') as file:
        content = file.read()

    # Replace \r with \n
    content = content.replace('\r', '\n')

    # Create the subfolder if it doesn't exist
    subfolder = 'utf'
    if not os.path.exists(subfolder):
        os.makedirs(subfolder)

    # Get the base name of the file and create the new file path
    base_name = os.path.basename(file_path)
    new_file_path = os.path.join(subfolder, base_name)

    # Write the modified content to the new file in the subfolder
    with open(new_file_path, 'w', encoding='utf-8') as file:
        file.write(content)

# Example usage
replace_carriage_return('Mas Sasquatch.txt')
replace_carriage_return('Microban.txt')
replace_carriage_return('Microcosmos.txt')
replace_carriage_return('Minicosmos.txt')
replace_carriage_return('Nabokosmos.txt')
replace_carriage_return('Picokosmos.txt')
replace_carriage_return('Sasquatch III.txt')
replace_carriage_return('Sasquatch IV.txt')
replace_carriage_return('Sasquatch V.txt')
replace_carriage_return('Sasquatch.txt')
replace_carriage_return('Sokoban Jr. 1.txt')
replace_carriage_return('Sokoban Jr. 2.txt')
replace_carriage_return('Sokogen 990602.txt')
replace_carriage_return('Yoshio Automatic.txt')
replace_carriage_return('dh1.txt')
replace_carriage_return('dh2.txt')