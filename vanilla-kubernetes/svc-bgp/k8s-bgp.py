#!/usr/bin/env python

import json
import requests
import collections
import time
import os 

cert_path_default = "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
token_path_default = "/var/run/secrets/kubernetes.io/serviceaccount/token"

node_name = os.environ.get("SVC_BGP_NODE_NAME")
api = os.environ.get("SVC_BGP_API_ENDPOINT","https://kubernetes.default")
cert_path = os.environ.get("SVC_BGP_API_CERT", cert_path_default)
token_path = os.environ.get("SVC_BGP_API_TOKEN", token_path_default)

with open(token_path) as f:
    token=f.read().strip()

host = collections.namedtuple("host",("name", "podcidr"))
endpoint = collections.namedtuple("endpoint",
    ("name","namespace","ip","node", "kind"))

service = collections.namedtuple("service",
    ("name","namespace","ip"))

node = collections.namedtuple("node",
    ("name","ip"))

route = collections.namedtuple("route",
    ("dstip","nexthop"))

def api_read(path):
    return requests.get(
        "{api}{path}".format(api=api,path=path), 
        verify=cert_path, 
        headers={"authorization":"bearer {token}".format(token=token) })

def parse_subsets(row,name,namespace):
    node = None
    ip = None
    kind = 'service'
    try:
        for address in row['addresses']:
            ip = address['ip']
            node = address['nodeName']
            kind = address['targetRef']['kind']
            yield endpoint(
                name, namespace, ip, node, kind)
    except KeyError:
        yield endpoint(
            name, namespace, ip, node, kind)

def generate_endpoints():
    endpoints = {} 
    path = "/api/v1/endpoints"
    endpoints_r = api_read(path)

    for line in json.loads(endpoints_r.text)['items']:
        name = line['metadata']['name']
        namespace = line['metadata']['namespace']
        for row in line['subsets']:
            endpoints[(name, namespace)] = list(parse_subsets(row,name,namespace))
    return endpoints

def generate_services():
    services = {}
    path = "/api/v1/services"
    services_r = api_read(path)

    for line in json.loads(services_r.text)['items']:
        ip = line['spec']['clusterIP']
        name = line['metadata']['name']
        namespace = line['metadata']['namespace']
        
        services[(name,namespace)] = service(name, namespace, ip)
     
    return services

def generate_nodes():
    nodes = {} 
    path = "/api/v1/nodes"
    nodes_r = api_read(path)

    for line in json.loads(nodes_r.text)['items']:
        name = line['metadata']['name']
        ip = line['status']['addresses'][0]['address']
        
        nodes[name] = node(name, ip)

    return nodes

def build_routes(node_name):
    endpoints = generate_endpoints()
    services = generate_services() 
    nodes = generate_nodes()
    routes = set()

    for svc in services.values():
        for ep in endpoints.get((svc.name,svc.namespace),[]):
            if ep.node == node_name or ep.ip == nodes[node_name].ip:
                routes.add(route(svc.ip,nodes[node_name].ip))

    return routes

def main():
    old_routes = set()
    while True:    
        routes = build_routes(node_name)
        
        added_routes = routes - old_routes
        deleted_routes = old_routes - routes

        for rt in added_routes:
            print "announce route {dstip}/32 next-hop {nexthop}".format(dstip=rt.dstip, nexthop=rt.nexthop)

        for rt in deleted_routes:
            print "withdraw route {dstip}/32 next-hop {nexthop}".format(dstip=rt.dstip, nexthop=rt.nexthop)
        old_routes = routes
        time.sleep(1)


main()

