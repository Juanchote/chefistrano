# Awesome capistrano recipe for deploying chef servers (a.k.a chefistrano since now)

## What is Chefistrano??

Chefistrano is a tool for deploying chef server nodes to anywhere around the universe.

## Why use Chefistrano??

Because is awesome.

## How can I buy and use this wonderful tool called Chefistrano?

Paypal button will be implemented soon.

## Ok, I already donated a lot of money to the team, how does it works??

Install vagrant in your local machine

download the repo (you know.. dah git cloneh stuffz)

then run
```
vagrant up
```

watch and feel the magic running through your monitor.

Enter inside this perfect machine
```
vagrant ssh
```

inside `/vagrant` folder there is a whole new world waiting for you to rediscover chef.

usage:

configure your deploy.rb / environments/<environment>.rb

then:
```
cap staging setup
```

Will launch the full process of provisioning.. omg do you feel the unicorns running through the internet??

run `cap staging -T` for extra tasks info.

The task will create deployer user, grant sudo permissions, install chef-server & chef-client, configure knife, download workstation and upload cookbooks and roles.


# HOW TO: ADD NODES
edit `files/<stage>/nodes.yml`

Add or replace the nodes
the syntax is:
```
-
  name: <name of the node>
  role: <role to apply>
```

# All this is only at a paypal click from you.
