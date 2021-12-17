import os
import uuid
template = open('template.ovf','r').read().split('$')
uuid1 = uuid.uuid4()
uuid2 = uuid.uuid4()
print(template[0], end='')
print(os.path.getsize('essence/bin/drive'), end='')
print(template[1], end='')
print(uuid1, end='')
print(template[2], end='')
print(uuid2, end='')
print(template[3], end='')
print(uuid1, end='')
print(template[4], end='')
