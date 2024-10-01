import re
import os
import subprocess

def remove_ansi_escape_codes(text):
    ansi_escape = re.compile(r'\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])')
    return ansi_escape.sub('', text)

readme_file = "README.md"

if not os.path.exists(readme_file):
    print(f"Error: {readme_file} not found.")
    exit()

with open(readme_file, "r") as f:
    readme_content = f.read()

start_comment_tag = "<!-- HELP-COMMAND-OUTPUT:START -->"
stop_comment_tag = "<!-- HELP-COMMAND-OUTPUT:END -->"

comment_tag_pattern = rf"{start_comment_tag}(.*?){stop_comment_tag}"
tag_section_content = re.search(comment_tag_pattern, readme_content, re.DOTALL)

if tag_section_content:

    try:
        help_command_output_new = subprocess.check_output(["brew", "autoupdate", "--help"], text=True)
    except subprocess.CalledProcessError as e:
        print(f"Error running command: {e}")
        exit()

    help_command_output_current = tag_section_content.group(1).strip()
    help_command_output_new = remove_ansi_escape_codes(help_command_output_new.strip())

    start_code_pattern = "```shell"
    end_code_pattern = "```"

    # Regex to check if the existing help section is in a shell code block
    code_block_pattern = re.compile(fr'^{re.escape(start_code_pattern)}.*?\n(.*(?:\n.*)*)\n{re.escape(end_code_pattern)}$', re.DOTALL)
    help_command_output_current = re.sub(code_block_pattern, r'\1', help_command_output_current)

    if help_command_output_current != help_command_output_new:
        print("Content change detected.")
        help = f"{start_comment_tag}\n{start_code_pattern}\n{help_command_output_new}\n{end_code_pattern}\n{stop_comment_tag}"
        readme_content = re.sub(comment_tag_pattern, help, readme_content, flags=re.DOTALL)
        print("Content updated.")

        # Set GitHub Actions output variable
        with open(os.environ['GITHUB_OUTPUT'], 'a') as fh:
            print(f'changed=true', file=fh)
    else:
        print("No change detected. Content remains unchanged.")
else:
    print(f"Error: Unable to find {start_comment_tag} and {stop_comment_tag} in {readme_file}.")

with open(readme_file, "w") as f:
    f.write(readme_content)
