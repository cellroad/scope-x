#!/usr/bin/bash

ruby scope.rb

echo ""
echo ""

read -p "Ender the target domain :" domain
echo ""
echo "subdomain enumeration started on $domain"

if [ -z "$domain" ]; then
    echo "[!] Domain required"
    exit 1
fi

output="recon_$domain"
mkdir -p $output/{subs,alive,urls,js,params,scan}
echo "[*] Target domain:$domain" 
echo "[*] Output dir: $output"

enum_subs() {
    echo "[*] Enumerating subdomains......... "
    subfinder -d "$domain" -silent > $output/subs/subs1.txt
    echo "[*] subfinder scann finished..."
    echo ""
    assetfinder --subs-only "$domain" > $output/subs/subs2.txt
    echo ""
    echo "[*]assetfinder scann finished ...."
    echo ""
    echo "[*]soring duplicate subdomains ...."
    cat "$output/subs/subs1.txt" "$output/subs/subs2.txt" | sort -u > $output/subs/allsub.txt
    echo ""
if [[ -s "$output/subs/subs1.txt" ]]; then

    echo "[*]subfinder output found $(wc -l < "$output/subs/subs1.txt")"
    echo ""
else
    echo "[*]subdomains not found at "$domain/subs/subs1.txt"
fi

 if [[ -s "$output/subs/subs2.txt" ]]; then

    echo "[*]assetfinder output found: $(wc -l < "$output/subs/subs2.txt")"
    echo ""
else
    echo "[*]subdomains not found at:"$domain/subs/subs2.txt"
fi
    echo "[*]all subdomain saved on output: $(wc -l < "$output/subs/allsub.txt")"

 }


http_alive() {

echo "[*]starting httpx scanning ..."

httpx -l $output/subs/allsub.txt -o $output/alive/httpx1.txt -silent

 }

extract_url() {

echo "[+] Collecting URLs..."
    waybackurls < $output/alive/httpx1.txt > $output/urls/wayback.txt

    if command -v katana &> /dev/null; then
        katana -list $output/alive/httpx1.txt -silent -o $output/urls/katana.txt
        cat $output/urls/*.txt | sort -u > $output/urls/all.txt
    else
        sort -u $output/urls/wayback.txt > $output/urls/all.txt
    fi
 }

collect_js() {
echo "[*] start js enumeration"

 echo "[+] Extracting JS files..."

    grep "\.js" $output/urls/all.txt | sort -u > $output/js/js.txt

katana -list $output/alive/httpx1.txt -o $output/js/js2.txt -js-crawl -silent

}

endpoit_params() {

echo "[+] Filtering potential vulns..."

    cat $output/urls/all.txt | gf xss > $output/params/xss.txt 2>/dev/null
    cat $output/urls/all.txt | gf sqli > $output/params/sqli.txt 2>/dev/null
    cat $output/urls/all.txt | gf lfi > $output/params/lfi.txt 2>/dev/null
    cat $output/urls/all.txt | gf rce > $output/params/rce.txt 2>/dev/null
    cat $output/urls/all.txt | gf idor > $output/params/idor.txt 2>/dev/null
    cat $output/urls/all.txt | gf ssrf > $output/params/ssrf.txt 2>/dev/null
}

run() {
enum_subs
http_alive
extract_url
collect_js
endpoit_params
}
run
