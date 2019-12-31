# IMS: Infrastructure monitoring system
<b>IMS: Infrastructure monitoring system</b><br>
This is really old project, created for home "datacenter" hardware monitoring.<br>
Project uses <a href="https://sourceforge.net/projects/synalist/">Ararat Synapse library</a>, but internal network protocol is designed from the scratch.<br>
service - main service, can be executed as linux daemon or windows service.<br>
MC - management console. Control center for whole system, should be connected to running service. Connection to other physical machines via network is allowed.<br>
AI - information agent. Read-only notification client, should be connected to running service. Connection to other physical machines via network is allowed.<br>
