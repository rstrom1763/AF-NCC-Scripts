#from ast import Num
#from itertools import count
#from typing import Counter
#from numpy import number
import requests
import time
#import os
'''
test_data = '{"computername":"prprl-05teb99","very test":"lol"}'
counter = 1
while counter > 0:
    
    headers_dict = {'Content-Type': 'text/plain',"computername":"MAUL"}
    try:
        test = requests.get('http://localhost:8081/get',
                            data=test_data, verify=False, headers=headers_dict)
    except Exception as e:
        print(e)
        time.sleep(5)
        


    #os.system('cls')
    print(test.content.decode())
    time.sleep(.05)

    counter = counter - 1
'''

test = requests.get('http://plex:8081/csvtest')
print(test.content.decode())