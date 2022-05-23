::: {.cell .markdown}


##  Home network

:::


::: {.cell .markdown}

### Set up bastion keys

In the next step, we will set up personal variables before attempting to reserve resources. It's important that you get the variables right *before* you import the `fablib` library, because `fablib` loads these once when imported and they can't be changed afterwards.

The important details to get right are the bastion username and the bastion key pair:

* bastion username: look for the string after "Bastion login" on [the SSH Keys page in the FABRIC portal](https://portal.fabric-testbed.net/experiments#sshKeys)
* bastion key pair: if you haven't yet set up bastion keys in your notebook environment (for example, in a previous session), complete the steps described in the [bastion keypair](https://github.com/fabric-testbed/jupyter-examples/blob/master//fabric_examples/fablib_api/bastion_setup.ipynb) notebook. Then, the key location you specify below should be the path to the private key file.


We also need to create an SSH config file, with settings for accessing the bastion gateway.

:::


::: {.cell .code}

```python
import os

# Set your Bastion username and private key
os.environ['FABRIC_BASTION_USERNAME']='ffund_0041777137'
os.environ['FABRIC_BASTION_KEY_LOCATION']=os.environ['HOME']+'/work/bastion-notebook'

# You can leave the rest on the default settings
# Set the keypair FABRIC will install in your slice. 
os.environ['FABRIC_SLICE_PRIVATE_KEY_FILE']=os.environ['HOME']+'/.ssh/id_rsa'
os.environ['FABRIC_SLICE_PUBLIC_KEY_FILE']=os.environ['HOME']+'/.ssh/id_rsa.pub'
# Bastion IPs
os.environ['FABRIC_BASTION_HOST'] = 'bastion-1.fabric-testbed.net'

# make sure the bastion key exists in that location!
# this cell should print True
os.path.exists(os.environ['FABRIC_BASTION_KEY_LOCATION'])

# prepare to share these with Bash so we can write the SSH config file
FABRIC_BASTION_USERNAME = os.environ['FABRIC_BASTION_USERNAME']
FABRIC_BASTION_KEY_LOCATION = os.environ['FABRIC_BASTION_KEY_LOCATION']
FABRIC_SLICE_PRIVATE_KEY_FILE = os.environ['FABRIC_SLICE_PRIVATE_KEY_FILE']
FABRIC_BASTION_HOST = os.environ['FABRIC_BASTION_HOST']
```
:::


::: {.cell .code}

```bash
%%bash -s "$FABRIC_BASTION_USERNAME" "$FABRIC_BASTION_KEY_LOCATION"

chmod 600 $2

export FABRIC_BASTION_SSH_CONFIG_FILE=${HOME}/.ssh/config

echo "Host bastion-*.fabric-testbed.net"    >  ${FABRIC_BASTION_SSH_CONFIG_FILE}
echo "     User $1"                         >> ${FABRIC_BASTION_SSH_CONFIG_FILE}
echo "     IdentityFile $2"                 >> ${FABRIC_BASTION_SSH_CONFIG_FILE}
echo "     StrictHostKeyChecking no"        >> ${FABRIC_BASTION_SSH_CONFIG_FILE}
echo "     UserKnownHostsFile /dev/null"    >> ${FABRIC_BASTION_SSH_CONFIG_FILE}

cat ${FABRIC_BASTION_SSH_CONFIG_FILE}
```
:::


::: {.cell .markdown}

### Reserve resources


:::


::: {.cell .markdown}

Give your slice a unique name. You can also set the FABRIC site at which you want to reserve resources in the cell below:

:::


::: {.cell .code}

```python
SLICENAME=os.environ['FABRIC_BASTION_USERNAME'] + "-home-network"
SITE="TACC"
```
:::

::: {.cell .markdown}

Now we are ready to import `fablib`! And we'll use it to see what resources are available at FABRIC sites.
:::


::: {.cell .code}

```python
import json
import traceback
from fabrictestbed_extensions.fablib.fablib import fablib
```
:::



::: {.cell .markdown}


If you already have the resources for this experiment (for example: you ran this part of the notebook previously, and are now returning to pick off where you left off), you don't need to reserve resources again. If the following cell tells you that you already have resources, you can just skip to the part where you left off last.


:::


::: {.cell .code}

```python
if fablib.get_slice(SLICENAME):
    print("You already have a slice named %s." % SLICENAME)
    slice = fablib.get_slice(name=SLICENAME)
    print(slice)
```
:::



::: {.cell .markdown}


Otherwise, set up your resource request and then submit it to FABRIC:

:::

::: {.cell .code}

```python
slice = fablib.new_slice(name=SLICENAME)


nodeRomeo  = slice.add_node(name="romeo",  site=SITE, cores=1, ram=4, image='default_ubuntu_20')
nodeJuliet = slice.add_node(name="juliet", site=SITE, cores=1, ram=4, image='default_ubuntu_20')
nodeRouter = slice.add_node(name="router", site=SITE, image='default_ubuntu_20')

ifaceRomeo   = nodeRomeo.add_component(model="NIC_Basic", name="if_romeo").get_interfaces()[0]
ifaceJuliet  = nodeJuliet.add_component(model="NIC_Basic", name="if_juliet").get_interfaces()[0]
ifaceRouterR = nodeRouter.add_component(model="NIC_Basic", name="if_router_r").get_interfaces()[0]
ifaceRouterJ = nodeRouter.add_component(model="NIC_Basic", name="if_router_j").get_interfaces()[0]

netR = slice.add_l2network(name='net_r', type='L2Bridge', interfaces=[ifaceRomeo,  ifaceRouterR])
netJ = slice.add_l2network(name='net_j', type='L2Bridge', interfaces=[ifaceJuliet, ifaceRouterJ])


slice.submit()
```
:::



::: {.cell .markdown}

Our final slice status should be "StableOK":

:::


::: {.cell .code}

```python
print(f"{slice}")
```
:::


::: {.cell .markdown}

and we can get login details for every node:

:::


::: {.cell .code}

```python
for node in slice.get_nodes():
    print(f"{node}")
```
:::



::: {.cell .markdown}

In the rest of this notebook, we'll execute commands on these nodes by accessing them over SSH. We'll define some variables with the login details and NIC names for the three nodes to assist with this:

:::


::: {.cell .code}

```python
# variables specific to this slice
ROMEO_IP = str(slice.get_node("romeo").get_management_ip())
ROMEO_USER =  str(slice.get_node("romeo").get_username())
ROMEO_IFACE_R = slice.get_interface_map()['net_r']['romeo']['ifname']

JULIET_IP = str(slice.get_node("juliet").get_management_ip())
JULIET_USER =  str(slice.get_node("juliet").get_username())
JULIET_IFACE_J = slice.get_interface_map()['net_j']['juliet']['ifname']


ROUTER_IP = str(slice.get_node("router").get_management_ip())
ROUTER_USER =  str(slice.get_node("router").get_username())
ROUTER_IFACE_J = slice.get_interface_map()['net_j']['router']['ifname']
ROUTER_IFACE_R = slice.get_interface_map()['net_r']['router']['ifname']
```
:::

