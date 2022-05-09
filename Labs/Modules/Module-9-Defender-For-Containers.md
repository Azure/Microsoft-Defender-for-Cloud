# Module 9 - Defender for Containers

<p align="left"><img src="../Images/asc-labs-advanced.gif?raw=true"></p>

#### 🎓 Level: 300 (Advanced)
#### ⌛ Estimated time to complete this lab: 60 minutes

## Objectives
This exercise guides you on how to validate and use Defender for Containers.

### Exercise 1: Install Docker Desktop

First you need to install Docker Desktop so that we can oush a vulnerable image to our existing Azure Container registry registy.

1.	Navigate to [Docker](https://www.docker.com/products/docker-desktop)  
2.  Download and install Docker, Check the system requirements, [Docker Requirements](https://docs.docker.com/get-docker/)
3.  After the installation, open PowerShell on your computer
4. Verify your docker version by executing in PowerShell 
```
    docker version​
```

You may see an output like the one below:


![Docker Version in Powershell](../Images/1dockerversion.png?raw=true)


### Exercise 2: Download vulnerable image from Docker Hub into the Container Registry

Now you will use Docker to download a vulnerable image from it and push it into the Container Registry you created using the ARM template in Lab 1.


1. Go to the Azure Portal and open the Container Registry (named "asclabcr####") that you created through the ARM template in Lab 1.
2. In the Overview of it, then please copy the Login server name only. 
![ACR server name](../Images/2acrserver.png?raw=true)


3.	Open PowerShell and run (where the NameOfServer is the one copied from above) the command below: <br />
```
az acr login --name NameOfServer
```
You might see an output like 


![ACR login](../Images/3acrlogin.png?raw=true)


4. Download vulnerable image from docker hub (which you can get more details at https://hub.docker.com/r/vulnerables/web-dvwa/),

by running the command below in Powershell:
```
docker pull vulnerables/web-dvwa
```


![ACR login](../Images/4dockerpullimage.png?raw=true)


5. Check the image on your local repository by running the command below:
```
docker pull vulnerables/web-dvwa
```
![Docker images](../Images/5dockerimages.png?raw=true)

6. Check again the image on your local repository by running the command below (replacingasclabcr### with the name of your server that copied above): 
```
Docker images asclabcr###.azurecr.io/vulnerables/web-dvwa
```
![Docker local repository](../Images/6dockerlocalrepo.png?raw=true)




7. Run docker push to upload the new image to the azure repository and generate image scan (it can take some time), using the command below: <br />
```
docker push secteach365.azurecr.io/vulnerables/web-dvwa:v1
```


![Docker push](../Images/7dockerpush.png?raw=true)



8. Then go to the Azure portal and find the Container registry you created.
9. Go to Repositories in the Container Registry. Notice the vulnerable image is found in the ACR repository.


![Image in ACR](../Images/8imageinacr.png?raw=true)



### Exercise 3: Investigate the recommendation for vulnerabilities in ACR

Once a vulnerable image has been pushed to the Azure Container Registry registry, then Microsoft Defender for Containers will start scanning the image for vulnerabilities, by using Qualys. You will now look into the recommendation in Microsoft Defender for Cloud for this. 
 
 1. Go to **Microsoft Defender for Cloud** in the **Azure Portal**.
 2. Go to the **Recommendations** tab in Defender for Cloud.
 3. In the **Resource type** filter, have it equal **Container registries**. <br />

 ![Recommendation for vulnerabilities in ACR](../Images/9recommendation.png?raw=true)
 4. Click on the recommendation **Container registry images should have vulnerability findings resolved** to get more details about it. <br />
 ![Recommendation for vulnerabilities in ACR More details](../Images/10recommendationmoreinfo.png?raw=true)
 <br />
 5. Look around at what's available in the recommendation. Take note of the Remediation Steps.
<br />
  ![Remediation Steps](../Images/remsteps.png?raw=true)
  <br />
 6. Select the vulnerability **Container registry images should have vulnerability findings resolved** to get more details about the patch available for it and how to remediate it.
 <br />
 ![Debian](../Images/11debian.png?raw=true)
 

