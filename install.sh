#!/bin/bash

domains=(one.tyras.dev two.tyras.dev) # You can name more than one domain separeiting them by space 
rsa_key_size=4096
data_path="./"
email="tyrunas@softpoint.lt" # Adding a valid address is strongly recommended
staging=0 # 1 use staging Let's Encryp enviroment , 0 1 use production Let's Encryp enviroment
docker_user="tyrunas" #your docker user in docker hub (optional), may be used for docker push later on 
image_name="nginx-certbot" # uses as image name as well as contianer name



echo "### Creating Data Directories ..."
mkdir -p ./data/nginx          
mkdir -p ./data/letsencrypt
mkdir -p ./data/www/certbot
echo "================================================================="

echo "### Building Images ..."
docker build . -t $docker_user"/"$image_name":latest"
echo "================================================================="

echo "### Runing docker for the first time ..."
docker container rm -f $image_name
docker container run -v $(pwd)/data/letsencrypt:/etc/letsencrypt -v $(pwd)/data/nginx:/etc/nginx/conf.d -v $(pwd)/data/www:/usr/share/nginx/html --name $image_name -p 80:80  -p 443:443 -d $docker_user"/"$image_name
cp ./nginx.conf ./data/nginx/default.conf
#cp ./index.html ./data/www/index.html
echo "================================================================="

echo "### Requesting Let's Encrypt certificates ..."
#Join $domains to -d args
domain_args=""
for domain in "${domains[@]}"; do
  domain_args="$domain_args -d $domain"
done
echo "DOMAINS ARE: "$domain_args
# Select appropriate email arg
case "$email" in
  "") email_arg="--register-unsafely-without-email" ;;
  *) email_arg="--email $email" ;;
esac
# Enable staging mode if needed
if [ $staging != "0" ]; then staging_arg="--staging"; fi
docker container exec -ti $image_name certbot  --nginx -w /usr/share/nginx/html/certbot $staging_arg $email_arg  $domain_args --rsa-key-size $rsa_key_size --agree-tos --eff-email --keep-until-expiring
echo "================================================================="
