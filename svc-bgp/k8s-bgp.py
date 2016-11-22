#!/usr/bin/env python

import json
import requests
import collections
import time

api = "https://kubernetes.default"

host = collections.namedtuple("host",("name", "podcidr"))
endpoint = collections.namedtuple("endpoint",
    ("name","namespace","ip","node", "kind"))

service = collections.namedtuple("service",
    ("name","namespace","ip"))

node = collections.namedtuple("node",
    ("name","ip"))

route = collections.namedtuple("route",
    ("dstip","nexthop"))

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
    endpoints_path = "/api/v1/endpoints"
    endpoints_r = requests.get(
        "{api}{path}".format(api=api,path=endpoints_path))

    for line in json.loads(endpoints_r.text)['items']:
        name = line['metadata']['name']
        namespace = line['metadata']['namespace']
        for row in line['subsets']:
            endpoints[(name, namespace)] = list(parse_subsets(row,name,namespace))
    return endpoints

def generate_services():
    services = {}
    services_path = "/api/v1/services"
    services_r = requests.get(
        "{api}{path}".format(api=api,path=services_path))

    for line in json.loads(services_r.text)['items']:
        ip = line['spec']['clusterIP']
        name = line['metadata']['name']
        namespace = line['metadata']['namespace']
        
        services[(name,namespace)] = service(name, namespace, ip)
     
    return services

def generate_nodes():
    nodes = {} 
    nodes_path = "/api/v1/nodes"
    nodes_r = requests.get(
        "{api}{path}".format(api=api,path=nodes_path))

    for line in json.loads(nodes_r.text)['items']:
        name = line['metadata']['name']
        ip = line['status']['addresses'][0]['address']
        
        nodes[name] = node(name, ip)

    return nodes

def build_routes():
    endpoints = generate_endpoints()
    services = generate_services() 
    nodes = generate_nodes()
    routes = set()

    for svc in services.values():
        for ep in endpoints[(svc.name,svc.namespace)]:
            if ep.node == None and ep.ip != None:
                routes.add(route(svc.ip,ep.ip))
            elif ep.ip != None:
                routes.add(route(svc.ip,nodes[ep.node].ip))

    return routes

def main():
    old_routes = set()
    while True:    
        routes = build_routes()
        
        added_routes = routes - old_routes
        deleted_routes = old_routes - routes

        for rt in added_routes:
            print "announce route {dstip}/32 next-hop {nexthop}".format(dstip=rt.dstip, nexthop=rt.nexthop)

        for rt in deleted_routes:
            print "withdraw route {dstip}/32 next-hop {nexthop}".format(dstip=rt.dstip, nexthop=rt.nexthop)
        old_routes = routes
        time.sleep(5)


main()

