::: {.cell .markdown}


## Set up environment

:::


::: {.cell .markdown}


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
```

:::


::: {.cell .code}


```python
# make sure the bastion key exists in that location!
# this cell should print True
os.path.exists(os.environ['FABRIC_BASTION_KEY_LOCATION'])
```

:::


::: {.cell .code}

```python
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
SLICENAME="ffund-meeting-demo"
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


Here is a complete list of FABRIC sites:

:::


::: {.cell .code}

```python
fablib.get_site_names()
```

:::


::: {.cell .markdown}

We can find out about available resources at each site. This will take a few minutes to run, as it queries the various FABRIC sites to find out what resources are available.

:::

::: {.cell .code}

```python
print(f"{fablib.list_sites()}")
```

:::

::: {.cell .markdown}

If we already have a slice (for example - we started working on this earlier and are picking it up again later), we can skip the next section, and just load the existing slice.

:::


::: {.cell .code}


```python
if fablib.get_slice(SLICENAME):
    print("You already have a slice named %s - skip the next part." % SLICENAME)
    slice = fablib.get_slice(name=SLICENAME)
    print(slice)
```

:::


::: {.cell .markdown}


## Create a slice and add resources

:::

::: {.cell .markdown}

We will use `fablib` to create a slice and set up the resources that we want in it.

:::


::: {.cell .code}


```python
slice = fablib.new_slice(name=SLICENAME)
```

:::

::: {.cell .markdown}

When we reserve our resources, we'll specify the disk image that should be pre-installed on the hosts. The choices include CentOS, Debian, Fedora, OpenBSD, Rocky Linux, and Ubuntu:

:::


::: {.cell .code}


```python
fablib.get_image_names()
```

:::

::: {.cell .markdown}

The default is Rocky Linux, which is kind of a weird choice.

To add a node to the slice, we'll use the `add_node()` function. Here's the current documenation for this function:

:::


::: {.cell .code}


```python
print(f"{slice.add_node.__doc__}")
```

:::


::: {.cell .markdown}


We see that when I add a node, I can specify:

* `name` - this will become part of the node hostname 
* `site` - any from the list above
* `image` - any from the list above
* `cores` - default is 2
* `ram` - default is 8GB
* `disk` - default is 10GB
* `site` - what FABRIC site to use

I will now add three nodes to my slice:

:::


::: {.cell .code}


```python
nodeRomeo  = slice.add_node(name="romeo",  site='TACC', cores=1, ram=4, image='default_ubuntu_20')
nodeJuliet = slice.add_node(name="juliet", site='TACC', cores=1, ram=4, image='default_ubuntu_20')
nodeRouter = slice.add_node(name="router", site='TACC', image='default_ubuntu_20')
```

:::


::: {.cell .code}


```python
print(f"{slice.list_nodes()}")
```

:::



::: {.cell .markdown}

Now we need to add network services. We will use the `add_component` method of the `node`, which is for adding network interfaces and GPUs. Here's its documentation:

:::


::: {.cell .code}

```python
print(f"{nodeRomeo.add_component.__doc__}")
```

:::


::: {.cell .markdown}

We'll prepare interfaces for a line topology, with a router connecting romeo and juliet. Note that we save specifically the *interface* from the component that is returned.

:::


::: {.cell .code}


```python
ifaceRomeo   = nodeRomeo.add_component(model="NIC_Basic", name="if_romeo").get_interfaces()[0]
ifaceJuliet  = nodeJuliet.add_component(model="NIC_Basic", name="if_juliet").get_interfaces()[0]
ifaceRouterR = nodeRouter.add_component(model="NIC_Basic", name="if_router_r").get_interfaces()[0]
ifaceRouterJ = nodeRouter.add_component(model="NIC_Basic", name="if_router_j").get_interfaces()[0]
```

:::


::: {.cell .code}


```python
print(f"{slice.list_interfaces()}")
```

:::


::: {.cell .markdown}

Now, we need two networks. FABRIC offers a few different type of networks. We'll look at the documentation to learn more.

:::


::: {.cell .code}


```python
print(f"{slice.add_l2network.__doc__}")
```

:::


::: {.cell .code}


```python
print(f"{slice.add_l3network.__doc__}")
```

:::


::: {.cell .markdown}

For this experiment, we'll use a couple of `L2Bridge` networks - one on each side of the router.

:::


::: {.cell .code}

```python
netR = slice.add_l2network(name='net_r', type='L2Bridge', interfaces=[ifaceRomeo,  ifaceRouterR])
netJ = slice.add_l2network(name='net_j', type='L2Bridge', interfaces=[ifaceJuliet, ifaceRouterJ])
```

:::


::: {.cell .code}


```python
print(f"{slice.list_interfaces()}")
```

:::


::: {.cell .markdown}

Note: Basic NICs claim 0 bandwidth but are 100 Gbps shared by all Basic NICs on the host.


:::

::: {.cell .markdown}

Now we are ready to reserve the resources and get the login details.

This step will take a little while, as we communicate with FABRIC to reserve our requested resources. 

- As it runs, you will see the "State" of each node go from "Ticketed" to "Active" (and a "Management IP", which may be IPv4 or IPv6, will be assigned to each one)
- Then, you'll wait a few more minutes for some `wait_ssh` and `post_boot_config` processes to run.
- Next, it will show the MAC address and interface name of each of the "dataplane" interfaces you set up, as these come up

:::


::: {.cell .code}


```python
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

Now our nodes are ready to log in. (In fact, you can launch a Bash terminal directly in this Jupyter environment, copy the SSH command, and log in to an interactive session.)

:::

::: {.cell .markdown}


## Set up variables

:::

::: {.cell .markdown}


We're going to switch to Bash in a moment. But first, we're going to set up some variables in Python3 that we will share with our Bash commands.

We need:

* the login details for each host (username and management IP address)
* the name of each network interface on each dataplane network, which we can get with this handy `get_interface_map` function

:::


::: {.cell .code}


```python
slice.get_interface_map()
```

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


::: {.cell .markdown}

Now, we have a few ways to run commands on a remote host.

:::

::: {.cell .markdown}

We can open a launcher and then SSH directly to get a terminal interface:

:::


::: {.cell .code}

```bash
%%bash -s "$FABRIC_SLICE_PRIVATE_KEY_FILE" "$FABRIC_BASTION_USERNAME" "$FABRIC_BASTION_HOST" "$ROMEO_USER" "$ROMEO_IP"
echo "ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $1 -J $2@$3 $4@$5"
```

:::

::: {.cell .markdown}

We can use the `fablib` Python library to execute commands on the remote host::

:::


::: {.cell .code}


```python
slice.get_node('romeo').execute("echo 'Hello from:'; hostname")
```

:::


::: {.cell .markdown}

Or we can use Bash "magic" in our notebook to run commands over SSH:

:::


::: {.cell .code}


```bash
%%bash -s "$FABRIC_SLICE_PRIVATE_KEY_FILE" "$FABRIC_BASTION_USERNAME" "$FABRIC_BASTION_HOST" "$ROMEO_USER" "$ROMEO_IP"
ssh -q -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=/dev/null -i $1 -J $2@$3 $4@$5 << EOF
##############################################

echo 'Hello from:'; hostname

##############################################
exit
EOF
```

:::

::: {.cell .markdown}


## Set up resources over SSH

:::

::: {.cell .markdown}


In our initial setup, we will:

* `touch ~/.hushlogin` so we don't have to see the login banner for each cell
* install some software packages

:::


::: {.cell .code}


```bash
%%bash -s "$FABRIC_SLICE_PRIVATE_KEY_FILE" "$FABRIC_BASTION_USERNAME" "$FABRIC_BASTION_HOST" "$ROMEO_USER" "$ROMEO_IP" "$ROMEO_IFACE_R"
ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $1 -J $2@$3 $4@$5 << EOF
##############################################

touch ~/.hushlogin
sudo apt update
sudo apt -y install net-tools iperf3 moreutils

##############################################
exit
EOF
```

:::


::: {.cell .code}


```bash
%%bash -s "$FABRIC_SLICE_PRIVATE_KEY_FILE" "$FABRIC_BASTION_USERNAME" "$FABRIC_BASTION_HOST" "$JULIET_USER" "$JULIET_IP" "$JULIET_IFACE_J"
ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $1 -J $2@$3 $4@$5 << EOF
##############################################

touch ~/.hushlogin
sudo apt update
sudo apt -y install net-tools iperf3 moreutils

##############################################
exit
EOF
```

:::


::: {.cell .code}


```bash
%%bash -s "$FABRIC_SLICE_PRIVATE_KEY_FILE" "$FABRIC_BASTION_USERNAME" "$FABRIC_BASTION_HOST" "$ROUTER_USER" "$ROUTER_IP"
ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $1 -J $2@$3 $4@$5 << EOF
##############################################

touch ~/.hushlogin
sudo apt update
sudo apt -y install net-tools

##############################################
exit
EOF
```

:::

::: {.cell .markdown}


Next, we will set up networking.

:::


::: {.cell .code}


```bash
%%bash -s "$FABRIC_SLICE_PRIVATE_KEY_FILE" "$FABRIC_BASTION_USERNAME" "$FABRIC_BASTION_HOST" "$ROMEO_USER" "$ROMEO_IP" "$ROMEO_IFACE_R"
ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $1 -J $2@$3 $4@$5 << EOF
##############################################

sudo ip addr add 192.168.0.2/24 dev $6
sudo ip route add 192.168.1.0/24 via 192.168.0.1 dev $6 

ip addr show dev $6
ip route show

##############################################
exit
EOF
```

:::


::: {.cell .code}

```bash
%%bash -s "$FABRIC_SLICE_PRIVATE_KEY_FILE" "$FABRIC_BASTION_USERNAME" "$FABRIC_BASTION_HOST" "$JULIET_USER" "$JULIET_IP" "$JULIET_IFACE_J"
ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $1 -J $2@$3 $4@$5 << EOF
##############################################

sudo ip addr add 192.168.1.2/24 dev $6
sudo ip route add 192.168.0.0/24 via 192.168.1.1 dev $6 

ip addr show dev $6
ip route show

##############################################
exit
EOF
```

:::


::: {.cell .code}

```bash
%%bash -s "$FABRIC_SLICE_PRIVATE_KEY_FILE" "$FABRIC_BASTION_USERNAME" "$FABRIC_BASTION_HOST" "$ROUTER_USER" "$ROUTER_IP" "$ROUTER_IFACE_R" "$ROUTER_IFACE_J"
ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $1 -J $2@$3 $4@$5 << EOF
##############################################

sudo ip addr add 192.168.0.1/24 dev $6
sudo ip addr add 192.168.1.1/24 dev $7
sudo sysctl -w net.ipv4.ip_forward=1

ip addr show dev $6
ip addr show dev $7
ip route show

##############################################
exit
EOF
```

:::

::: {.cell .markdown}


Now we can test it! We will `ping` from romeo to juliet:

:::


::: {.cell .code}

```bash
%%bash -s "$FABRIC_SLICE_PRIVATE_KEY_FILE" "$FABRIC_BASTION_USERNAME" "$FABRIC_BASTION_HOST" "$ROMEO_USER" "$ROMEO_IP" "$ROMEO_IFACE_R"
ssh -q -o StrictHostKeyChecking=no -i $1 -J $2@$3 $4@$5 << EOF
##############################################

ping -c 5 192.168.1.2

##############################################
exit
EOF
```

:::

::: {.cell .markdown}


Let's also test capacity across this network. To do this, we need to start an `iperf3` server in the *background* on juliet:

:::


::: {.cell .code}


```bash
%%bash --bg -s "$FABRIC_SLICE_PRIVATE_KEY_FILE" "$FABRIC_BASTION_USERNAME" "$FABRIC_BASTION_HOST" "$JULIET_USER" "$JULIET_IP"
ssh  -q -o StrictHostKeyChecking=no -i $1 -J $2@$3 $4@$5 << EOF
##############################################

iperf3 -1 -s

##############################################
exit
EOF
```

:::

::: {.cell .markdown}


Then we can run the `iperf3` client on romeo (in the *foreground*):

:::

```bash
%%bash -s "$FABRIC_SLICE_PRIVATE_KEY_FILE" "$FABRIC_BASTION_USERNAME" "$FABRIC_BASTION_HOST" "$ROMEO_USER" "$ROMEO_IP"
ssh  -q -o StrictHostKeyChecking=no -i $1 -J $2@$3 $4@$5 << EOF
##############################################

iperf3 -t 10 -i 1 -c 192.168.1.2

##############################################
exit
EOF
```

::: {.cell .markdown}


For this experiment, we will configure the router as a 10Mbps bottleneck:


```bash
%%bash -s "$FABRIC_SLICE_PRIVATE_KEY_FILE" "$FABRIC_BASTION_USERNAME" "$FABRIC_BASTION_HOST" "$ROUTER_USER" "$ROUTER_IP" "$ROUTER_IFACE_R" "$ROUTER_IFACE_J"
ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $1 -J $2@$3 $4@$5 << EOF
##############################################

sudo tc qdisc del dev $6 root  
sudo tc qdisc add dev $6 root handle 1: htb default 3  
sudo tc class add dev $6 parent 1: classid 1:3 htb rate 10Mbit  
sudo tc qdisc add dev $6 parent 1:3 handle 3: bfifo limit 0.1MB
sudo tc qdisc show dev $6
        
sudo tc qdisc del dev $7 root  
sudo tc qdisc add dev $7 root handle 1: htb default 3  
sudo tc class add dev $7 parent 1: classid 1:3 htb rate 10Mbit  
sudo tc qdisc add dev $7 parent 1:3 handle 3: bfifo limit 0.1MB  
sudo tc qdisc show dev $7

##############################################
exit
EOF
```

::: {.cell .markdown}


Let's validate this capacity now:


```bash
%%bash --bg -s "$FABRIC_SLICE_PRIVATE_KEY_FILE" "$FABRIC_BASTION_USERNAME" "$FABRIC_BASTION_HOST" "$JULIET_USER" "$JULIET_IP"
ssh  -q -o StrictHostKeyChecking=no -i $1 -J $2@$3 $4@$5 << EOF
##############################################

iperf3 -1 -s

##############################################
exit
EOF
```


```bash
%%bash -s "$FABRIC_SLICE_PRIVATE_KEY_FILE" "$FABRIC_BASTION_USERNAME" "$FABRIC_BASTION_HOST" "$ROMEO_USER" "$ROMEO_IP"
ssh  -q -o StrictHostKeyChecking=no -i $1 -J $2@$3 $4@$5 << EOF
##############################################

iperf3 -t 10 -i 1 -c 192.168.1.2

##############################################
exit
EOF
```

::: {.cell .markdown}


## TCP congestion control experiment

::: {.cell .markdown}


Now we are ready to run the actual experiment!

Our first demo will be this [basic congestion control](https://witestlab.poly.edu/blog/tcp-congestion-control-basics/) experiment.

On the juliet host, set up an `iperf3` server in the *background* with


```bash
%%bash --bg -s "$FABRIC_SLICE_PRIVATE_KEY_FILE" "$FABRIC_BASTION_USERNAME" "$FABRIC_BASTION_HOST" "$JULIET_USER" "$JULIET_IP"
ssh  -q -o StrictHostKeyChecking=no -i $1 -J $2@$3 $4@$5 << EOF
##############################################

iperf3 -1 -s

##############################################
exit
EOF
```

::: {.cell .markdown}


Then, we will run two commands in quick sequence. The first one will start an `iperf3` client process in the background 5 seconds after we run the cell. The second one will run in the foreground and collect data about TCP sessions. (Note: we have to escape the `$` character in our Bash script.)


```bash
%%bash --bg -s "$FABRIC_SLICE_PRIVATE_KEY_FILE" "$FABRIC_BASTION_USERNAME" "$FABRIC_BASTION_HOST" "$ROMEO_USER" "$ROMEO_IP"
ssh  -q -o StrictHostKeyChecking=no -i $1 -J $2@$3 $4@$5 << EOF
##############################################

sleep 5
iperf3 -c 192.168.1.2 -i 1 -P 3 -t 60 -C reno -w 100k > iperf-out.txt

##############################################
exit
EOF
```


```bash
%%bash -s "$FABRIC_SLICE_PRIVATE_KEY_FILE" "$FABRIC_BASTION_USERNAME" "$FABRIC_BASTION_HOST" "$ROMEO_USER" "$ROMEO_IP"
ssh  -q -o StrictHostKeyChecking=no -i $1 -J $2@$3 $4@$5 << EOF
##############################################

touch sender-ss.txt
rm -f sender-ss.txt

timetorun=70    # in seconds
stoptime=\$((timetorun + \$(date +%s)))
while [ \$(date +%s) -lt \$stoptime ]; do
        ss --no-header -ein dst 192.168.1.2  | ts '%.s' >> sender-ss.txt 
done

# make sure it looks OK
tail -n 5 sender-ss.txt

##############################################
exit
EOF
```

::: {.cell .markdown}

After 70 seconds, the experiment run will be over.  Check the `iperf3` output to make sure it looks good.


```bash
%%bash -s "$FABRIC_SLICE_PRIVATE_KEY_FILE" "$FABRIC_BASTION_USERNAME" "$FABRIC_BASTION_HOST" "$ROMEO_USER" "$ROMEO_IP"
ssh  -q -o StrictHostKeyChecking=no -i $1 -J $2@$3 $4@$5 << EOF
##############################################

tail -n 12 iperf-out.txt

##############################################
exit
EOF
```

::: {.cell .markdown}

Then, process the `ss` data. Note that we need to escape `$` symbols in our processing script.


```bash
%%bash -s "$FABRIC_SLICE_PRIVATE_KEY_FILE" "$FABRIC_BASTION_USERNAME" "$FABRIC_BASTION_HOST" "$ROMEO_USER" "$ROMEO_IP"
ssh  -q -o StrictHostKeyChecking=no -i $1 -J $2@$3 $4@$5 << EOF
##############################################

# get timestamp
ts=\$(cat sender-ss.txt |   sed -e ':a; /<->$/ { N; s/<->\n//; ba; }' | grep "ESTAB" | grep "unacked" |  awk '{print \$1}')

# get sender
sender=\$(cat sender-ss.txt |   sed -e ':a; /<->$/ { N; s/<->\n//; ba; }' | grep "ESTAB" | grep "unacked" | awk '{print \$6}')

# retransmissions - current, total
retr=\$(cat sender-ss.txt |   sed -e ':a; /<->$/ { N; s/<->\n//; ba; }' | grep "ESTAB" | grep -oP '\bunacked:.*\brcv_space'  | awk -F '[:/ ]' '{print \$4","\$5}' | tr -d ' ')

# get cwnd, ssthresh
cwn=\$(cat sender-ss.txt |   sed -e ':a; /<->$/ { N; s/<->\n//; ba; }' | grep "ESTAB" | grep "unacked" | grep -oP '\bcwnd:.*(\s|$)\bbytes_acked' | awk -F '[: ]' '{print \$2","\$4}')

# concatenate into one CSV
paste -d ',' <(printf %s "\$ts") <(printf %s "\$sender") <(printf %s "\$retr") <(printf %s "\$cwn") > sender-ss.csv

# check a few lines
tail -n 5 sender-ss.csv
##############################################
exit
EOF
```

::: {.cell .markdown}

## Data analysis

::: {.cell .markdown}

One nice thing about working in a notebook is that we can do data analysis inline!

First, we retrieve the data file from the romeo host. We can call `download_file` on the node, specifying the local path to save to and the remote path to download from.


```python
slice.get_node("romeo").download_file("/home/fabric/work/sender-ss.csv", "/home/ubuntu/sender-ss.csv")
```


```python
import pandas as pd
import matplotlib.pyplot as plt
```


```python
df = pd.read_csv("sender-ss.csv", names=['time', 'sender', 'retx_unacked', 'retx_cum', 'cwnd', 'ssthresh'])
df
```

One of the flows is the "control" flow, which we'll want to exclude from our analysis:


```python
s = df.groupby('sender').size()
s
```


```python
df_filtered = df[df.groupby("sender")['sender'].transform('size') > 100]
df_filtered
```


```python
senders = df_filtered.sender.unique()
senders
```


```python
time_min = df_filtered.time.min()
cwnd_max = 1.1*df_filtered[df_filtered.time - time_min >=2].cwnd.max()
dfs = [df_filtered[df_filtered.sender==senders[i]] for i in range(3)]
```


```python
fig, axs = plt.subplots(len(senders), sharex=True, figsize=(12,8))
fig.suptitle('CWND over time')
for i in range(len(senders)):
    if i==len(senders)-1:
        axs[i].plot(dfs[i]['time']-time_min, dfs[i]['cwnd'], label="cwnd")
        axs[i].plot(dfs[i]['time']-time_min, dfs[i]['ssthresh'], label="ssthresh")
        axs[i].set_ylim([0,cwnd_max])
        axs[i].set_xlabel("Time (s)");
    else:
        axs[i].plot(dfs[i]['time']-time_min, dfs[i]['cwnd'])
        axs[i].plot(dfs[i]['time']-time_min, dfs[i]['ssthresh'])
        axs[i].set_ylim([0,cwnd_max])


plt.tight_layout();
fig.legend(loc='upper right', ncol=2);

```

::: {.cell .markdown}

## Adaptive video experiment 


::: {.cell .markdown}


Our next experiment will be this [adaptive video](https://witestlab.poly.edu/blog/adaptive-video-reproducing/) experiment.

Set up juliet as an adaptive video "server". We will run this in the background, just so that we can continue to romeo in the meantime, but we need to make sure it's finished before we start the experiment.


```bash
%%bash --bg -s "$FABRIC_SLICE_PRIVATE_KEY_FILE" "$FABRIC_BASTION_USERNAME" "$FABRIC_BASTION_HOST" "$JULIET_USER" "$JULIET_IP"
ssh  -q -o StrictHostKeyChecking=no -i $1 -J $2@$3 $4@$5 << EOF
##############################################

sudo apt install -y apache2  
wget https://nyu.box.com/shared/static/d6btpwf5lqmkqh53b52ynhmfthh2qtby.tgz -O media.tgz  
sudo tar -v -xzf media.tgz -C /var/www/html/  

##############################################
exit
EOF
```

::: {.cell .markdown}


Set up romeo as an adaptive video "client".


```bash
%%bash -s "$FABRIC_SLICE_PRIVATE_KEY_FILE" "$FABRIC_BASTION_USERNAME" "$FABRIC_BASTION_HOST" "$ROMEO_USER" "$ROMEO_IP"
ssh  -q -o StrictHostKeyChecking=no -i $1 -J $2@$3 $4@$5 << EOF
##############################################

sudo apt install -y python2 ffmpeg

##############################################
exit
EOF
```


::: {.cell .markdown}

In this experiment, we will use the DASH implementation developed for the following paper:

> P. Juluri, V. Tamarapalli and D. Medhi, "SARA: Segment aware rate adaptation algorithm for dynamic adaptive streaming over HTTP," 2015 IEEE International Conference on Communication Workshop (ICCW), 2015, pp. 1765-1770, doi: 10.1109/ICCW.2015.7247436.

which is available on [Github](https://github.com/pari685/AStream). It includes three DASH decision policies:

The "basic" policy selects the video rate that is one level lower than the current network data rate. You can see [the "basic" implementation here](https://github.com/pari685/AStream/blob/master/dist/client/adaptation/basic_dash2.py).

The buffer-based rate adaptation ("Netflix") algorithm uses the estimated network data rate only during the initial startup phase. Otherwise, it makes quality decisions based on the buffer occupancy. It is based on the algorithm described in the following paper:

> Te-Yuan Huang, Ramesh Johari, Nick McKeown, Matthew Trunnell, and Mark Watson. 2014. A buffer-based approach to rate adaptation: evidence from a large video streaming service. In Proceedings of the 2014 ACM conference on SIGCOMM (SIGCOMM '14). Association for Computing Machinery, New York, NY, USA, 187–198. DOI:https://doi.org/10.1145/2619239.2626296

You can see [the "Netflix" implementation here](https://github.com/pari685/AStream/blob/master/dist/client/adaptation/netflix_dash.py). 

Finally, the segment-aware rate adaptation ("SARA") algorithm uses the actual size of the segment and data rate of the network to estimate the time it would take to download the next segment. Then, given the current buffer occupancy, it selects the best possible video quality while avoiding buffer starvation. It is described in 

> P. Juluri, V. Tamarapalli and D. Medhi, "SARA: Segment aware rate adaptation algorithm for dynamic adaptive streaming over HTTP," 2015 IEEE International Conference on Communication Workshop (ICCW), 2015, pp. 1765-1770, doi: 10.1109/ICCW.2015.7247436.

You can see [the "SARA" implementation here](https://github.com/pari685/AStream/blob/master/dist/client/adaptation/weighted_dash.py).

We will retrieve this open-source implementation on romeo:



```bash
%%bash -s "$FABRIC_SLICE_PRIVATE_KEY_FILE" "$FABRIC_BASTION_USERNAME" "$FABRIC_BASTION_HOST" "$ROMEO_USER" "$ROMEO_IP"
ssh  -q -o StrictHostKeyChecking=no -i $1 -J $2@$3 $4@$5 << EOF
##############################################

git clone https://github.com/pari685/AStream  

##############################################
exit
EOF
```

::: {.cell .markdown}

Make sure the video server is ready on juliet. The output should show the BigBuckBunny directories:


```bash
%%bash -s "$FABRIC_SLICE_PRIVATE_KEY_FILE" "$FABRIC_BASTION_USERNAME" "$FABRIC_BASTION_HOST" "$JULIET_USER" "$JULIET_IP"
ssh  -q -o StrictHostKeyChecking=no -i $1 -J $2@$3 $4@$5 << EOF
##############################################

ls /var/www/html/media/BigBuckBunny/4sec

##############################################
exit
EOF
```

::: {.cell .markdown}


The web server directory now contains 4-second segments of the "open" video clip [Big Buck Bunny](https://peach.blender.org/about/), encoded at different quality levels. The Big Buck Bunny DASH dataset is from:

> Stefan Lederer, Christopher Müller, and Christian Timmerer. 2012. Dynamic adaptive streaming over HTTP dataset. In Proceedings of the 3rd Multimedia Systems Conference (MMSys '12). Association for Computing Machinery, New York, NY, USA, 89–94. DOI:https://doi.org/10.1145/2155555.2155570


Now, we can try an experiment! We will retrieve the first 30 segments of the video, using the "netflix" policy. But we will also set the router data rate to be 1Mbps for 20 seconds, then 100Kbps for 20 seconds, and then back to 1Mbps.


```bash
%%bash --bg -s "$FABRIC_SLICE_PRIVATE_KEY_FILE" "$FABRIC_BASTION_USERNAME" "$FABRIC_BASTION_HOST" "$ROUTER_USER" "$ROUTER_IP" "$ROUTER_IFACE_R" "$ROUTER_IFACE_J"
ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $1 -J $2@$3 $4@$5 << EOF
##############################################

sudo tc qdisc del dev $6 root  
sudo tc qdisc add dev $6 root handle 1: htb default 3  
sudo tc class add dev $6 parent 1: classid 1:3 htb rate 1Mbit  
sudo tc qdisc add dev $6 parent 1:3 handle 3: bfifo limit 0.1MB
sudo tc qdisc show dev $6
        
sudo tc qdisc del dev $7 root  
sudo tc qdisc add dev $7 root handle 1: htb default 3  
sudo tc class add dev $7 parent 1: classid 1:3 htb rate 1Mbit  
sudo tc qdisc add dev $7 parent 1:3 handle 3: bfifo limit 0.1MB  
sudo tc qdisc show dev $7

sleep 20

sudo tc qdisc del dev $6 root  
sudo tc qdisc add dev $6 root handle 1: htb default 3  
sudo tc class add dev $6 parent 1: classid 1:3 htb rate 100Kbit  
sudo tc qdisc add dev $6 parent 1:3 handle 3: bfifo limit 0.1MB
sudo tc qdisc show dev $6
        
sudo tc qdisc del dev $7 root  
sudo tc qdisc add dev $7 root handle 1: htb default 3  
sudo tc class add dev $7 parent 1: classid 1:3 htb rate 100Kbit  
sudo tc qdisc add dev $7 parent 1:3 handle 3: bfifo limit 0.1MB  
sudo tc qdisc show dev $7

sleep 20


sudo tc qdisc del dev $6 root  
sudo tc qdisc add dev $6 root handle 1: htb default 3  
sudo tc class add dev $6 parent 1: classid 1:3 htb rate 1Mbit  
sudo tc qdisc add dev $6 parent 1:3 handle 3: bfifo limit 0.1MB
sudo tc qdisc show dev $6
        
sudo tc qdisc del dev $7 root  
sudo tc qdisc add dev $7 root handle 1: htb default 3  
sudo tc class add dev $7 parent 1: classid 1:3 htb rate 1Mbit  
sudo tc qdisc add dev $7 parent 1:3 handle 3: bfifo limit 0.1MB  
sudo tc qdisc show dev $7

##############################################
exit
EOF
```


```bash
%%bash -s "$FABRIC_SLICE_PRIVATE_KEY_FILE" "$FABRIC_BASTION_USERNAME" "$FABRIC_BASTION_HOST" "$ROMEO_USER" "$ROMEO_IP"
ssh  -q -o StrictHostKeyChecking=no -i $1 -J $2@$3 $4@$5 << EOF
##############################################

python2 ~/AStream/dist/client/dash_client.py -m http://192.168.1.2/media/BigBuckBunny/4sec/BigBuckBunny_4s.mpd -p 'netflix' -n 30 -d

##############################################
exit
EOF
```

::: {.cell .markdown}

The log files will be inside `ASTREAM_LOGS`, and the video files will be inside a directory beginning with `TEMP_`. We will get the directory/file names from this next command, and use it to modify the following cells.


```bash
%%bash -s "$FABRIC_SLICE_PRIVATE_KEY_FILE" "$FABRIC_BASTION_USERNAME" "$FABRIC_BASTION_HOST" "$ROMEO_USER" "$ROMEO_IP"
ssh  -q -o StrictHostKeyChecking=no -i $1 -J $2@$3 $4@$5 << EOF
##############################################

ls -alstr ~/
ls -alstr ~/ASTREAM_LOGS

##############################################
exit
EOF
```

::: {.cell .markdown}

We can recreate the video from the segments, which are stored in the `TEMP_` directory.


```bash
%%bash -s "$FABRIC_SLICE_PRIVATE_KEY_FILE" "$FABRIC_BASTION_USERNAME" "$FABRIC_BASTION_HOST" "$ROMEO_USER" "$ROMEO_IP"
ssh  -q -o StrictHostKeyChecking=no -i $1 -J $2@$3 $4@$5 << EOF
##############################################

cd ~/TEMP_MBvypN
rm -f BigBuckBunny.mp4 # if it exists
cat BigBuckBunny_4s_init.mp4 \$(ls -vx BigBuckBunny_*.m4s) > BigBuckBunny_tmp.mp4
ffmpeg -i  BigBuckBunny_tmp.mp4 -c copy BigBuckBunny.mp4

mv BigBuckBunny.mp4 ~/

##############################################
exit
EOF
```


```python
slice.get_node("romeo").download_file("/home/fabric/work/BigBuckBunny.mp4", "/home/ubuntu/BigBuckBunny.mp4")
```


```python
from IPython.display import Video

Video("BigBuckBunny.mp4")
```

::: {.cell .markdown}

We can also retrieve the adaptive video log data.


```python
slice.get_node("romeo").download_file("/home/fabric/work/DASH_BUFFER_LOG.csv", "/home/ubuntu/ASTREAM_LOGS/DASH_BUFFER_LOG_2022-04-14.14_55_27.csv")
```

::: {.cell .markdown}

and do some data analysis:


```python
import matplotlib.pyplot as plt
import pandas as pd

c = {'INITIAL_BUFFERING': 'violet', 'PLAY': 'lightcyan', 'BUFFERING': 'lightpink'}

dash = pd.read_csv("DASH_BUFFER_LOG.csv")
dash = dash.loc[dash.CurrentPlaybackState.isin(c.keys() )]
states = pd.DataFrame({'startState': dash.CurrentPlaybackState[0:-2].values, 'startTime': dash.EpochTime[0:-2].values,
                        'endState':  dash.CurrentPlaybackState[1:-1].values, 'endTime':   dash.EpochTime[1:-1].values})


for index, s in states.iterrows():
  plt.axvspan(s['startTime'], s['endTime'],  color=c[s['startState']], alpha=1) 

plt.plot(dash[dash.Action!="Writing"].EpochTime, dash[dash.Action!="Writing"].Bitrate, 'kx:')
plt.title("Video rate (bps)");
plt.xlabel("Time (s)");
```

::: {.cell .markdown}


## Delete slice


::: {.cell .markdown}


When you are finished, delete your slice to free resources for other experimenters.


```python
fablib.delete_slice(SLICENAME)
```
