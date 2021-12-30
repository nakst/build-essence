import os
for config_file in os.listdir('apps/samples'):
    if config_file.endswith('.ini'):
        source_file = config_file.split('.')[0] + '.c'
        if not os.path.exists('apps/samples/' + source_file):
            source_file = config_file.split('.')[0] + '.cpp'
        if not os.path.exists('apps/samples/' + source_file):
            continue
        application_name = None
        with open('apps/samples/' + config_file, 'r') as config_fd:
            config = config_fd.read().split('\n')
            config_section = ''
            for config_line in config:
                if len(config_line) > 0 and config_line[0] == '[':
                    config_section = config_line
                elif config_section == '[general]' and config_line.startswith('name='):
                    application_name = config_line[5:]
        if not application_name: 
            continue
        print(application_name, source_file, config_file)
        folder = 'root/API Samples/' + application_name
        try:
            os.mkdir(folder)
        except:
            pass
        with open('apps/samples/' + source_file, 'r') as source_fd:
            with open(folder + '/' + source_file, 'w') as source_dest_fd:
                source_dest_fd.write(source_fd.read())
        with open('apps/samples/' + config_file, 'r') as config_fd:
            with open(folder + '/make.build_core', 'w') as config_dest_fd:
                config = config_fd.read().split('\n')
                config_section = ''
                for config_line in config:
                    if len(config_line) > 0 and config_line[0] == '[':
                        config_section = config_line
                    if config_section == '[build]' and config_line.startswith('source='):
                        config_dest_fd.write('source=' + source_file + '\n')
                    else:
                        config_dest_fd.write(config_line + '\n')
