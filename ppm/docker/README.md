PPM docker image creation. Build commands are below:
-------------------------------------------------------------------------------------------------------------------------

	docker build -t ppm_15.6.0.122 --build-arg SFTP_LOCATION=sftp://builder:Niku#1234@ppmoseutil.ca.com:22/home/builder/ppm --build-arg CAPA_ZIP=CAPA/capa_v15.4_12.1.0.3.1.zip --build-arg THIRDPARTY_JAR=thirdparty.libs.15.6.0.jar --build-arg PPM_INSTALLER=saas.clarity.15.6.0.122.zip .

    docker tag ppm_15.6.0.122 itc-dsdc.ca.com:5000/clarity/common/ppm_15.6.0.122:latest

    docker push itc-dsdc.ca.com:5000/clarity/common/ppm_15.6.0.122:latest

-------------------------------------------------------------------------------------------------------------------------

Run PPM container to install only DB Schema:

    docker run -it -p 8081:8081 --env-file <path>/ppm.properties ppm_15.6.0.122 "INSTALL_DB"

Run PPM container to start the app service:

    docker run -it -p 8081:8081 --env-file <path>/ppm.properties ppm_15.6.0.122

Run PPM container to start the bg service:

    docker run -it -p 8081:8081 --env-file <path>/ppm.properties ppm_15.6.0.122 "bg"

Note: E.g. for ppm.properties located in configfiles folder	
-------------------------------------------------------------------------------------------------------------------------


