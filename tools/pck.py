import struct,hashlib

def pack(files,path):
    header=struct.pack('<6IQ16II',0x43504447,2,4,6,3,0,0,*([0]*16),len(files))
    offset=len(header)+sum(4+len(k.encode())+(-len(k.encode())%4)+36 for k in files)
    records=[];data=[]
    for k,v in files.items():
        n=k.encode();n+=b'\0'*(-len(n)%4)
        records.append(struct.pack('<I',len(n))+n+struct.pack('<QQ',offset,len(v))+hashlib.md5(v).digest()+struct.pack('<I',0));data.append(v);offset+=len(v)
    path.write_bytes(header+b''.join(records)+b''.join(data))