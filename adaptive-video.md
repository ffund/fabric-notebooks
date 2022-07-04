::: {.cell .markdown}


##  Adaptive video

This experiment explores the tradeoff between different metrics of video quality (average rate, interruptions, and variability of rate) in an adaptive video delivery system.

This experiment runs on the [FABRIC JupyterHub server](https://jupyter.fabric-testbed.net/). You will need an account on FABRIC, and you will need to have set up bastion keys, to run it.

It should take about 60-120 minutes to run this experiment.

:::


::: {.cell .markdown}

## Background

**Note:** Parts of this section are reproduced from [a blog post on adaptive video](https://witestlab.poly.edu/blog/adaptive-video/).


:::

::: {.cell .markdown}


### Adaptive video


:::

::: {.cell .markdown}

In general high-quality video requires a higher data rate than a lower-quality equivalent. Consider the following two video frames. The first shows a video encoded at 200kbps:

![](https://witestlab.poly.edu/blog/content/images/2016/02/dash-200.png)

Here's the same frame at 500kbps, with noticeably better quality:

![](https://witestlab.poly.edu/blog/content/images/2016/02/dash-500.png)


:::

::: {.cell .markdown}


For web services that want to share video with their users, this poses a dilemma - what quality level should they use to encode the video? If a video is low quality, it will stream without interruption even on a slow 3G cellular connection, but a user on a high speed fiber network may be unhappy with the video quality. Or, the video may be high quality, but then the slow connection would not be able to stream it without constant interruptions.

Fortunately, there is a solution to this dilemma: adaptive video. Instead of delivering exactly the same video to every user, adaptive video delivers video that is matched to the individual user's network quality.

There are many different adaptive video products: Microsoft Smooth Streaming, Apple HTTP Live Streaming (HLS), Adobe HTTP Dynamic Streaming (HDS), and Dynamic Adaptive Streaming over HTTP (DASH). This experiment focuses on DASH, which is widely supported as an international standard. 



:::

::: {.cell .markdown}


To prepare a video for adaptive video streaming with DASH, the video file is first encoded into different versions, each having a different rate and/or resolution. These are called *representations* or media presentations. The representations of a video all have the same content, but they differ in quality.

Each of these is further subdivided in time into *segments* of equal lengths (e.g., four seconds).

![](https://witestlab.poly.edu/blog/content/images/2016/02/dash-stored.png)

The content server then stores all of the segments of all of the representations (as separate files). Alongside these files, the content server stores a manifest file, called the Media Presentation Description (MPD). This is an XML file that identifies the various representations, identifies the video resolution and playback rate for each, and gives the location of every segment in each representation.

With these preparations complete, a user can begin to stream adaptive video from the server!


:::

::: {.cell .markdown}

Once the MPD and video files are in place, users can start requesting DASH video.

First, the user requests the MPD file. It parses the MPD file, learns what representations are available, and decides what representation to request for the first segment. It then retrieves that specific file using the URL given in the MPD.

The user's device keeps a video buffer (at the application layer). As new segments are retrieved, they are placed in the buffer. As video is played back, it is removed from the buffer. 

Each time a client finishes retrieving a file into the buffer, it makes a new decision as to what representation to get for the next segment.


For example, the client might request the following representations for the first four segments of video:

![](https://witestlab.poly.edu/blog/content/images/2016/02/dash-requested.png)

The cumulative set of decisions made by the client is called a decision policy. The decision policy is a set of rules that determine which representation to request, based on some kind of client state - for example, what the current download rate is, or how much video is currently stored in the buffer.

The decision policy is not specified in the DASH standard. Many decision policies have been proposed by researchers, each promising to deliver better quality than the next!


:::

::: {.cell .markdown}

### DASH decision policies


:::

::: {.cell .markdown}

The obvious policy to maximize video quality alone would be to always retrive segments at the highest quality level. However, with this policy the user is likely to experience rebuffering - when playback is interrupted and the user has to wait for more video to be downloaded. This occurs when the video is being played back (and therefore, removed from the buffer) faster than it is being retrieved - i.e., the playback rate is higher than the download rate - so the buffer becomes empty. This state, which is known as buffer starvation, is obviously something we wish very much to avoid.


To create a positive user experience for streaming video, therefore, requires a delicate balancing act.

* On the one hand, increasing the video playback rate too much (so that it is higher than the download rate) causes the undesired rebuffers.
* On the other hand, decreasing the video playback rate also decreases the user-perceived video quality.


Performing rate selection to balance rebuffer avoidance and quality optimization is an ongoing tradeoff. Different DASH policies may make different decisions about how to balance that tradeoff. Different DASH policies may also decide to use different pieces of information for decision making. For example:
 
* A decision policy may decide to focus on download rate in its decision making - select the quality level for the next video segment according to the download rate from the previous segment(s).
* Or, a decision policy may focus on buffer occupancy (how much video is already downloaded into the buffer, waiting to be played back?) If there is already a lot of video in the buffer, the decision policy can afford to be aggressive in its quality selection, since it has a cushion to protect it from rebuffering. On the other hand, if there is not much video in the buffer, the decision policy should be careful not to select a quality level that is too optimistic, since it is at high risk of rebuffering.


:::

::: {.cell .markdown}

### Specific policies in this implementation


:::

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


:::

::: {.cell .markdown}

## Run my experiment

:::

::: {.cell .markdown}

### Set up bastion keys

In the next step, we will set up personal variables before attempting to reserve resources. It's important that you get the variables right *before* you import the `fablib` library, because `fablib` loads these once when imported and they can't be changed afterwards.

The important details to get right are the bastion username and the bastion key pair:

* project ID: in the FABRIC portal, click on User Profile > My Roles and Projects > and click on your project name. Then copy the Project ID string.
* bastion username: look for the string after "Bastion login" on [the SSH Keys page in the FABRIC portal](https://portal.fabric-testbed.net/experiments#sshKeys)
* bastion key pair: if you haven't yet set up bastion keys in your notebook environment (for example, in a previous session), complete the steps described in the [bastion keypair](https://github.com/fabric-testbed/jupyter-examples/blob/master//fabric_examples/fablib_api/bastion_setup.ipynb) notebook. Then, the key location you specify below should be the path to the private key file.


We also need to create an SSH config file, with settings for accessing the bastion gateway.

:::


::: {.cell .code}

```python
import os

# Specify your project ID
os.environ['FABRIC_PROJECT_ID']='XXXXXXXXXXXX'

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
SLICENAME=os.environ['FABRIC_BASTION_USERNAME'] + "-adaptive-video"
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
ROMEO_IFACE_R = slice.get_node("romeo").get_interfaces()[0].get_os_interface()

JULIET_IP = str(slice.get_node("juliet").get_management_ip())
JULIET_USER =  str(slice.get_node("juliet").get_username())
JULIET_IFACE_J = slice.get_node("juliet").get_interfaces()[0].get_os_interface()


ROUTER_IP = str(slice.get_node("router").get_management_ip())
ROUTER_USER =  str(slice.get_node("router").get_username())
ROUTER_IFACE_J = slice.get_node("router").get_interface(name='router-if_router_j-p1').get_os_interface()
ROUTER_IFACE_R = slice.get_node("router").get_interface(name='router-if_router_r-p1').get_os_interface()
```
:::




::: {.cell .markdown}

### One-time setup


:::


::: {.cell .markdown}


### Set up network

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

### Set up for adaptive video experiment

:::

::: {.cell .markdown}


Next, we will set up juliet as an adaptive video "server". We will run this in the background, just so that we can continue to romeo in the meantime, but we need to make sure it's finished before we start the experiment.

:::


::: {.cell .code}


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

:::

::: {.cell .markdown}


Set up romeo as an adaptive video "client".


:::


::: {.cell .code}

```bash
%%bash -s "$FABRIC_SLICE_PRIVATE_KEY_FILE" "$FABRIC_BASTION_USERNAME" "$FABRIC_BASTION_HOST" "$ROMEO_USER" "$ROMEO_IP"
ssh  -q -o StrictHostKeyChecking=no -i $1 -J $2@$3 $4@$5 << EOF
##############################################

sudo apt install -y python2 ffmpeg

##############################################
exit
EOF
```

:::

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


:::


::: {.cell .code}

```bash
%%bash -s "$FABRIC_SLICE_PRIVATE_KEY_FILE" "$FABRIC_BASTION_USERNAME" "$FABRIC_BASTION_HOST" "$ROMEO_USER" "$ROMEO_IP"
ssh  -q -o StrictHostKeyChecking=no -i $1 -J $2@$3 $4@$5 << EOF
##############################################

git clone https://github.com/pari685/AStream  

##############################################
exit
EOF
```
:::

::: {.cell .markdown}

Make sure the video server is ready on juliet. The output should show the BigBuckBunny directories:

:::


::: {.cell .code}

```bash
%%bash -s "$FABRIC_SLICE_PRIVATE_KEY_FILE" "$FABRIC_BASTION_USERNAME" "$FABRIC_BASTION_HOST" "$JULIET_USER" "$JULIET_IP"
ssh  -q -o StrictHostKeyChecking=no -i $1 -J $2@$3 $4@$5 << EOF
##############################################

ls /var/www/html/media/BigBuckBunny/4sec

##############################################
exit
EOF
```
:::

::: {.cell .markdown}


The web server directory now contains 4-second segments of the "open" video clip [Big Buck Bunny](https://peach.blender.org/about/), encoded at different quality levels. The Big Buck Bunny DASH dataset is from:

> Stefan Lederer, Christopher Müller, and Christian Timmerer. 2012. Dynamic adaptive streaming over HTTP dataset. In Proceedings of the 3rd Multimedia Systems Conference (MMSys '12). Association for Computing Machinery, New York, NY, USA, 89–94. DOI:https://doi.org/10.1145/2155555.2155570



:::

::: {.cell .markdown}


### Execute experiment


:::

::: {.cell .markdown}

Now, we can try an experiment! We will retrieve the first 30 segments of the video, using the "netflix" policy. But we will also set the router data rate to be 1Mbps for 20 seconds, then 100Kbps for 20 seconds, and then back to 1Mbps.

:::


::: {.cell .code}


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

:::


::: {.cell .code}

```bash
%%bash -s "$FABRIC_SLICE_PRIVATE_KEY_FILE" "$FABRIC_BASTION_USERNAME" "$FABRIC_BASTION_HOST" "$ROMEO_USER" "$ROMEO_IP"
ssh  -q -o StrictHostKeyChecking=no -i $1 -J $2@$3 $4@$5 << EOF
##############################################

python2 ~/AStream/dist/client/dash_client.py -m http://192.168.1.2/media/BigBuckBunny/4sec/BigBuckBunny_4s.mpd -p 'netflix' -n 30 -d

##############################################
exit
EOF
```

:::

::: {.cell .markdown}

The log files will be inside `ASTREAM_LOGS`, and the video files will be inside a directory beginning with `TEMP_`. We will get the directory/file names from this next command, and use it to modify the following cells.

:::


::: {.cell .code}


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

:::


::: {.cell .markdown}


### Data analysis


:::

::: {.cell .markdown}

We can recreate the video from the segments, which are stored in the `TEMP_` directory.

:::


::: {.cell .code}

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

:::


::: {.cell .code}


```python
slice.get_node("romeo").download_file("/home/fabric/work/BigBuckBunny.mp4", "/home/ubuntu/BigBuckBunny.mp4")
```

:::


::: {.cell .code}


```python
from IPython.display import Video

Video("BigBuckBunny.mp4")
```

:::

::: {.cell .markdown}

We can also retrieve the adaptive video log data.

:::


::: {.cell .code}


```python
slice.get_node("romeo").download_file("/home/fabric/work/DASH_BUFFER_LOG.csv", "/home/ubuntu/ASTREAM_LOGS/DASH_BUFFER_LOG_2022-04-14.14_55_27.csv")
```
:::

::: {.cell .markdown}

and do some data analysis:

:::


::: {.cell .code}

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
:::


::: {.cell .markdown}


## Delete slice

:::

::: {.cell .markdown}


When you are finished, delete your slice to free resources for other experimenters.


:::


::: {.cell .code}

```python
fablib.delete_slice(SLICENAME)
```

:::
