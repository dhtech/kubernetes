#!/usr/bin/env python

import json
import requests

api = "http://master0.event.dreamhack.se:8080"

class host(object):
    def __init__(self, name, podcidr):
        self.name = name
        self.podcidr = podcidr

class endpoint(object):
    def __init__(self, name, namespace, ip, node, kind):
        self.name = name
        self.namespace = namespace
        self.ip = ip
        self.pods = []
        self.kind = kind
        self.node = node

class service(object):
    def __init__(self, name, namespace, ip):
        self.name = name
        self.namespace = namespace
        self.ip = ip

def generate_endpoints():
    endpoints = []
    endpoints_path = "/api/v1/endpoints"
    endpoints_r = requests.get(
        "{api}{path}".format(api=api,path=endpoints_path))

    for line in json.loads(endpoints_r.text)['items']:
        node = None
        kind = 'service' 
        name = line['metadata']['name']
        namespace = line['metadata']['namespace']
        ip = None
        for row in line['subsets']:
            try:
                for address in row['addresses']:
                    ip = address['ip']
                    node = address['nodeName']
                    kind = address['targetRef']['kind']
                    endpoints.append(endpoint(
                        name, namespace, ip, node, kind))
            except:
                endpoints.append(endpoint(
                    name, namespace, ip, node, kind))
    return endpoints

def generate_services():
    services = []
    services_path = ""
    
def main():
    services_path="/api/v1/services"
    services = []
    
    endpoints = generate_endpoints()
    

main()

