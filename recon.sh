#!/bin/bash

banner (){
echo -e "
+-+-+-+-+-+-+-+-+-+-+
|k|e|n|t|s|l|a|v|e|s|
+-+-+-+-+-+-+-+-+-+-+
AUTHOR: KENT BAYRON @Kntx"
}

kill (){
        banner
    echo -e "RECONNAISSANCE TOOL FOR BUGBOUNTY"
    echo "USAGE:./recon.sh domain.com"
    exit 1
}

recon(){
github_token=651ad30200a510891c8b34a74d2908a4a346a570
shodan init=wqASoYZk1E1rwkwkk9LSI8xeDKigldFj
banner
mkdir ~/Research/Targets/$1
mkdir ~/Research/Targets/$1/Shodan
mkdir ~/Research/Targets/$1/GitHub
mkdir ~/Research/Targets/$1/Screenshots
mkdir ~/Research/Targets/$1/Endpoints
mkdir ~/Research/Targets/$1/SubdomainTakeover
mkdir ~/Research/Targets/$1/JSFiles
mkdir ~/Research/Targets/$1/Smuggle
echo $1 > ~/Research/Targets/$1/$1.root.txt
cat ~/Research/Targets/$1/$1.root.txt  | grep -Po "[\w\s]+(?=\.)" >> ~/Research/Targets/$1/$1.domain.txt
cd ~/Research/Targets/$1
echo -e "\e[31m[STARTING]\e[0m"

## LAUNCH AMASS
echo -e "\nRUNNING \e[31m[AMASS PASSIVE]\e[0m"
amass enum -passive -d $1 -o ~/Research/Targets/$1/$1.amasspassive.txt 
echo "FOUND SUBDOMAINS [$(cat ~/Research/Targets/$1/$1.amasspassive.txt | wc -l)]"

## LAUNCH ASSETFINDER
echo -e "\nRUNNING \e[31m[ASSETFINDER]\e[0m"
assetfinder -subs-only $1 > ~/Research/Targets/$1/$1.assetfinder.txt
echo "FOUND SUBDOMAINS [$(cat ~/Research/Targets/$1/$1.assetfinder.txt | wc -l)]"

## LAUNCH FINDOMAIN
echo -e "\nRUNNING \e[31m[FINDOMAIN]\e[0m"
findomain -t $1 -o
echo "FOUND SUBDOMAINS [$(cat ~/Research/Targets/$1/$1.txt | wc -l)]"

## LAUNCH DNSBUFFER
echo -e "\nRUNNING \e[31m[DNSBUFFEROVER]\e[0m"
curl -s https://dns.bufferover.run/dns?q=.$1 | jq -r .FDNS_A[]|cut -d',' -f2 > ~/Research/Targets/$1/$1.dnsbuffer.txt
echo "FOUND SUBDOMAINS [$(cat ~/Research/Targets/$1/$1.dnsbuffer.txt | wc -l)]"

## LAUNCH SUBFINDER
echo -e "\nRUNNING \e[31m[SUBFINDER]\e[0m"
subfinder -d $1 -o ~/Research/Targets/$1/$1.subfinder.txt 
echo "FOUND SUBDOMAINS [$(cat ~/Research/Targets/$1/$1.subfinder.txt | wc -l)]"

## REMOVING DUPLICATES
sort  ~/Research/Targets/$1/$1.amasspassive.txt ~/Research/Targets/$1/$1.subfinder.txt ~/Research/Targets/$1/$1.txt ~/Research/Targets/$1/$1.assetfinder.txt ~/Research/Targets/$1/$1.dnsbuffer.txt | uniq > ~/Research/Targets/$1/$1.alldomains.txt

## LAUNCH DNSGEN & MASSDNS
echo -e "\nRUNNING \e[31m[MASSDNS & DNSGEN]\e[0m"
cat ~/Research/Targets/$1/$1.alldomains.txt | dnsgen - | ~/Research/Tools/Massdns/bin/massdns -r ~/Research/Tools/Massdns/lists/resolvers.txt -t A -o S -w ~/Research/Targets/$1/$1.massdns.txt
echo "RESOLVED SUBDOMAINS [$(cat ~/Research/Targets/$1/$1.massdns.txt | wc -l)]"

## REMOVING DUPLICATES
sort ~/Research/Targets/$1/$1.massdns.txt | awk '{print $1}' | sed 's/\.$//' | uniq > ~/Research/Targets/$1/$1.resolved.txt
sort ~/Research/Targets/$1/$1.resolved.txt ~/Research/Targets/$1/$1.alldomains.txt |  uniq > ~/Research/Targets/$1/$1.all-final.txt

## LAUNCH LIVEHOSTS
echo -e "\nRUNNING \e[31m[LIVEHOSTS]\e[0m"
cat ~/Research/Targets/$1/$1.all-final.txt | filter-resolved -c 100  >  ~/Research/Targets/$1/$1.all-resolved.txt 
cat ~/Research/Targets/$1/$1.all-final.txt | httprobe -c 100 >>  ~/Research/Targets/$1/$1.all-resolved.txt
cat ~/Research/Targets/$1/$1.all-resolved.txt | httprobe -c 100 >> ~/Research/Targets/$1/$1.livehost.txt
sort ~/Research/Targets/$1/$1.livehost.txt | uniq >> ~/Research/Targets/$1/$1.livehosts.txt
cat ~/Research/Targets/$1/$1.livehosts.txt | sed 's/https\?:\/\///' > ~/Research/Targets/$1/$1.probed.txt
echo "LIVE HOSTS [$(cat ~/Research/Targets/$1/$1.livehosts.txt | wc -l)]"

## LAUNCH HAKCRAWLER
echo -e "\nRUNNING \e[31m[HAKCRAWLER]\e[0m"
for hak in $(cat ~/Research/Targets/$1/$1.all-final.txt); do
       hakrawler -url $hak -depth 1 >> ~/Research/Targets/$1/$1.Crawler.txt
done
echo "RUNNING [OK]"

## RUNNING SHODAN
echo -e "\nRUNNING \e[31m[SHODAN HOST]\e[0m"
dig +short -f ~/Research/Targets/$1/$1.probed.txt > ~/Research/Targets/$1/ips.txt
cat ~/Research/Targets/$1/ips.txt | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' >> ~/Research/Targets/$1/ip.txt
sort ~/Research/Targets/$1/ip.txt | uniq > ~/Research/Targets/$1/$1.ip.txt
for ip in $(cat ~/Research/Targets/$1/$1.ip.txt);do shodan host $ip > ~/Research/Targets/$1/Shodan/$ip-shodan.txt; done 
echo "RUNNING SHODAN HOST [OK]"

## LAUNCH SUBJACK
echo -e "\nRUNNING \e[31m[SUBJACK]\e[0m"
subjack -w ~/Research/Targets/$1/$1.probed.txt -t 100 -a -timeout 30 -c ~/Research/Tools/Others/fingerprints.json -v -m -ssl -o ~/Research/Targets/$1/SubdomainTakeover/$1.result.txt 
echo "RUNNING SUBJACK [OK]"

## LAUNCH TKO-SUBS
echo -e "\nRUNNING \e[31m[TKO-SUBS]\e[0m"
tko-subs -domains=/root/Research/Targets/$1/$1.probed.txt -data=/root/Research/Tools/Others/providers-data.csv -output=/root/Research/Targets/$1/SubdomainTakeover/output.csv 
echo "RUNNING TKO-SUBS [OK]"

## LAUNCH WEB-ANALYZE
echo -e "\nRUNNING \e[31m[WEB-ANALYZE]\e[0m"
webanalyze -update
for a in $(cat ~/Research/Targets/$1/$1.livehosts.txt); do
	webanalyze -host $a >> ~/Research/Targets/$1/webanalyze.txt
done
rm apps.json
echo "RUNNING WEB-ANALYZE [OK]"

## RUNNING AQUATONE
echo -e "\nRUNNING \e[31m[AQUATONE ON SUBDOMAINS]\e[0m"
cat ~/Research/Targets/$1/$1.livehosts.txt | aquatone -threads 50 -out ~/Research/Targets/$1/Screenshots 
echo "RUNNING AQUATONE [OK]"

## RUNNING WEBSCREENSHOT
echo -e "\nRUNNING \e[31m[WEBSCREENSHOT]\e[0m"
webscreenshot -i ~/Research/Targets/$1/$1.livehosts.txt  -v  -o ~/Research/Targets/$1/Screenshots  
cd ~/Research/Targets/$1/Screenshots
for ws in $(ls); do
    echo "$ws" >> ws.html
    echo "<img src=$ws><br>" >> ws.html
done
echo "RUNNING WEBSCREENSHOT [OK]"

## RUNNING SMUGGLER
echo -e "\nRUNNING \e[31m[SMUGGLER]\e[0m"
python3 ~/Research/Tools/Smuggler/smuggler.py -v 1 -t 50 -u ~/Research/Targets/$1/$1.livehosts.txt >> ~/Research/Targets/$1/Smuggle/$1.Smuggled.txt 
echo "RUNNING SMUGGLER[OK]"

## RUNNING LINKFINDER
echo -e "\nRUNNING \e[31m[LINKFINDER]\e[0m"
sort ~/Research/Targets/$1/$1.livehosts.txt | sed 's/https\?:\/\///' | uniq >> ~/Research/Targets/$1/$1.livehosts-strip.txt
declare -a protocol=("http" "https")
for urlz in `cat ~/Research/Targets/$1/$1.livehosts-strip.txt`; do
        for protoc in ${protocol[@]}; do
                python3 ~/Research/Tools/LinkFinder/linkfinder.py -i $protoc://$urlz -d -o  ~/Research/Targets/$1/JSFiles/$protoc_$urlz-result.html 
        done
done
echo "RUNNING LINKFINDER [OK]"

## LAUNCH OTXURLS
echo -e "\nRUNNING \e[31m[OTXURLS]\e[0m"
cat ~/Research/Targets/$1/$1.all-final.txt | otxurls | uniq  >  ~/Research/Targets/$1/Endpoints/$1.otxurl.txt
echo "FOUND ENDPOINTS [$(cat ~/Research/Targets/$1/Endpoints/$1.otxurl.txt | wc -l)]"

## LAUNCH WAYBACKURLS
echo -e "\nRUNNING \e[31m[WAYBACKURLS]\e[0m"
cat ~/Research/Targets/$1/$1.all-final.txt | waybackurls | uniq > ~/Research/Targets/$1/Endpoints/$1.waybackruls.txt
echo "FOUND ENDPOINTS [$(cat ~/Research/Targets/$1/Endpoints/$1.waybackruls.txt | wc -l)]"

## LAUNCH COMMONCRAWL
echo -e "\nRUNNING \e[31m[COMMONCRAWL]\e[0m"
curl -sX GET "http://index.commoncrawl.org/CC-MAIN-2018-22-index?url=*.$(cat ~/Research/Targets/$1/$1.domain.txt)&output=json" | jq -r .url | uniq > ~/Research/Targets/$1/Endpoints/$1.commoncrawl.txt 
echo "FOUND ENDPOINTS [$(cat ~/Research/Targets/$1/Endpoints/$1.commoncrawl.txt | wc -l)]"

## LAUNCH GITHUB ENDPOINTS
echo -e "\nRUNNING \e[31m[GITHUB ENDPOINTS]\e[0m"
for git in $(cat ~/Research/Targets/$1/$1.root.txt);do python3 ~/Research/Tools/GitHubTool/github-endpoints.py -t $github_token -d $git -s -r > ~/Research/Targets/$1/GitHub/$git-endpoints.txt; done 
echo "FOUND ENDPOINTS [OK]"

## REMOVING DUPLICATES
echo -e "\nTOTAL \e[31m[ENDPOINTS]\e[0m"
cat  ~/Research/Targets/$1/Endpoints/$1.otxurl.txt ~/Research/Targets/$1/Endpoints/$1.waybackruls.txt ~/Research/Targets/$1/Endpoints/$1.commoncrawl.txt > ~/Research/Targets/$1/Endpoints/all-endpoints.txt
echo "TOTAL FOUND ENDPOINTS [$(cat ~/Research/Targets/$1/Endpoints/all-endpoints.txt | wc -l)]"

## REMOVING UNIQUE
cat ~/Research/Targets/$1/Endpoints/all-endpoints.txt | qsreplace -a  > ~/Research/Targets/$1/Endpoints/unique-endpoints.txt

## SEGRAGATING JSFILES
cat ~/Research/Targets/$1/Endpoints/all-endpoints.txt | grep "\.js$" > ~/Research/Targets/$1/Endpoints/jsfles.txt
echo "TOTAL FOUND JS ENDPOINTS [$(cat ~/Research/Targets/$1/Endpoints/jsfles.txt | wc -l)]"
echo "TOTAL FOUND UNIQUE ENDPOINTS [$(cat ~/Research/Targets/$1/Endpoints/unique-endpoints.txt | wc -l)]"
echo -e "\nRECON IS \e[32mFINISH\e[0m "

## REMOVING UNUSED FILES
#rm ~/Research/Targets/$1/$1.amasspassive.txt ~/Research/Targets/$1/$1.assetfinder.txt ~/Research/Targets/$1/$1.dnsbuffer.txt ~/Research/Targets/$1/$1.domain.txt ~/Research/Targets/$1/$1.livehosts-strip.txt ~/Research/Targets/$1/$1.massdns.txt ~/Research/Targets/$1/$1.probed.txt ~/Research/Targets/$1/$1.resolved.txt ~/Research/Targets/$1/$1.root.txt ~/Research/Targets/$1/$1.txt ~/Research/Targets/$1/ip.txt ~/Research/Targets/$1/$1.alldomains.txt

}

if [ -z "$1" ]
  then
    kill
else
        recon $1
fi
