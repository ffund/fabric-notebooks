::: {.cell .markdown}


##  Background

:::

::: {.cell .markdown}


This notebook shows how to compile a kernel on a FABRIC node, using the BBRv2 alpha kernel as an example.

:::


::: {.cell .markdown}


## Set up bastion keys

In the next step, we will set up personal variables before attempting to reserve resources. It's important that you get the variables right *before* you import the `fablib` library, because `fablib` loads these once when imported and they can't be changed afterwards.

The important details to get right are the bastion username and the bastion key pair:

* bastion username: look for the string after "Bastion login" on [the SSH Keys page in the FABRIC portal](https://portal.fabric-testbed.net/experiments#sshKeys)
* bastion key pair: if you haven't yet set up bastion keys in your notebook environment (for example, in a previous session), run the [bastion keypair](./fabric_examples/fablib_api/bastion_setup.ipynb) notebook. Then, the key location should be the path to the private key file.


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

echo "Host bastion-*.fabric-testbed.net"                        >  ${FABRIC_BASTION_SSH_CONFIG_FILE}
echo "     User $1"                                             >> ${FABRIC_BASTION_SSH_CONFIG_FILE}
echo "     IdentityFile $2"                                     >> ${FABRIC_BASTION_SSH_CONFIG_FILE}
echo "     StrictHostKeyChecking no"                            >> ${FABRIC_BASTION_SSH_CONFIG_FILE}
echo "     UserKnownHostsFile /dev/null"                        >> ${FABRIC_BASTION_SSH_CONFIG_FILE}

cat ${FABRIC_BASTION_SSH_CONFIG_FILE}
```
:::


::: {.cell .markdown}

Give your slice a unique name:

:::


::: {.cell .code}

```python
SLICENAME="ffund-bbrv2"
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


## Create a slice and add resources

We'll ask for a more capable node - a `fabric.c8.m32.d100` type:

:::


::: {.cell .code}

```python
try:
    slice = fablib.new_slice(name=SLICENAME)

    # Add node
    node = slice.add_node(name='host', 
                          site='TACC', 
                          cores=8, 
                          ram=32, 
                          disk=100, 
                          image='default_ubuntu_20')

    #Submit Slice Request
    slice.submit()
except Exception as e:
    print(f"Exception: {e}")
```
:::


::: {.cell .code}

```python
try:
    slice = fablib.get_slice(slice_name)
    for node in slice.get_nodes():
        print(node.get_ssh_command())
except Exception as e:
    print(f"Fail: {e}")
```
:::





::: {.cell .markdown}


## Delete slice

When you are finished, delete your slice to free resources for other experimenters.

:::


::: {.cell .code}
```python
fablib.delete_slice(SLICENAME)
```
:::