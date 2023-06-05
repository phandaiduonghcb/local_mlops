<!-- Improved compatibility of back to top link: See: https://github.com/othneildrew/Best-README-Template/pull/73 -->
<a name="readme-top"></a>
<!--
*** Thanks for checking out the Best-README-Template. If you have a suggestion
*** that would make this better, please fork the repo and create a pull request
*** or simply open an issue with the tag "enhancement".
*** Don't forget to give the project a star!
*** Thanks again! Now go create something AMAZING! :D
-->



<!-- PROJECT SHIELDS -->
<!--
*** I'm using markdown "reference style" links for readability.
*** Reference links are enclosed in brackets [ ] instead of parentheses ( ).
*** See the bottom of this document for the declaration of the reference variables
*** for contributors-url, forks-url, etc. This is an optional, concise syntax you may use.
*** https://www.markdownguide.org/basic-syntax/#reference-style-links
-->
[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![MIT License][license-shield]][license-url]
[![LinkedIn][linkedin-shield]][linkedin-url]



<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/phandaiduonghcb/local_mlops">
    <img src="images/logo.png" alt="Logo" width="80" height="80">
  </a>

<h3 align="center">Local MLOPs pipeline for a classification problem</h3>

  <p align="center">
    This repository contains source code, configuration files for setuping a MLOPs pipeline that can be automatically triggered to train and deploy the best model using AWS services.
    <br />
    <a href="https://github.com/phandaiduonghcb/local_mlops"><strong>Explore the docs »</strong></a>
    <br />
    <br />
    <a href="https://github.com/phandaiduonghcb/local_mlops">View Demo</a>
    ·
    <a href="https://github.com/phandaiduonghcb/local_mlops/issues">Report Bug</a>
    ·
    <a href="https://github.com/phandaiduonghcb/local_mlops/issues">Request Feature</a>
  </p>
</div>



<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
      <ul>
        <li><a href="#built-with">Built With</a></li>
      </ul>
    </li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#prerequisites">Prerequisites</a></li>
        <li><a href="#installation">Installation</a></li>
      </ul>
    </li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#roadmap">Roadmap</a></li>
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgments">Acknowledgments</a></li>
  </ol>
</details>



<!-- ABOUT THE PROJECT -->
## About The Project

[![Product Name Screen Shot][product-screenshot]](https://example.com)

<p align="right">(<a href="#readme-top">back to top</a>)</p>



### Built With

* [![Pytorch][Pytorch]][Pytorch-url]
* [![Mlflow][Mlflow]][Mlflow-url]
* [![Airflow][Airflow]][Airflow-url]
* [![DVC][DVC]][DVC-url]
* [![Docker][Docker]][Docker-url]
* [![Python][Python]][Python-url]
* [![AWS][AWS]][AWS-url]

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- GETTING STARTED -->
## Getting Started

Through this guide, I will try to explain how can I use AWS services and some tools to create an MLOPs pipeline that can be triggered to train and deploy everytime the latest commit whose message contains "Airflow" term is pushed. The repo is similar to this [mlops repo](https://github.com/phandaiduonghcb/mlops) but the training, testing process will be conducted in a local machine and I take the advantage of AWS Fargte and ECR for easier deployment process.
### Classification problem
A resnet18 neural network is used for image classification. The dataset is put into `./ml/data/train`, `./ml/data/valid`, `./ml/data/test`.
The configuration file for training, testing is put into `./ml/configs`.
The [flower dataset](https://public.roboflow.com/classification/flowers_classification/2) is taken as an example for this project.

### Code and Data versioning

DVC is used for data versioning and GIT is used for code versioning. Data cache is stored in a S3 remote storage.

* Install DVC:
  ```sh
    pip install dvc dvc-s3
  ```


* Use DVC to track your data. Remember to setup AWS credentials using `./server_setup/aws_config` and copy all files in that folder to `~/.aws/`
  ```sh
    dvc init
    dvc add ml/data/*
    git add ml/data/valid.dvc ml/data/test.dvc ml/data/train.dvc ml/data/.gitignore
    dvc remote add local-mlops-bucket s3://local-mlops-bucket
    dvc remote modify local-mlops-bucket profile duongpd7
    dvc push -r local-mlops-bucket
  ```

### Setup the local machine
Airflow will be installed in the local machine for training and testing process.
> **Note:**
> The working folder for Airflow docker container should be located in your $HOME path. Otherwise it doesn't work for me.
* Create working directory and prepare folders for volume mounting. After creating folders, copy **files** in `server_setup/`:
  ```sh
    mkdir workspace # Store logs, dags and training runs created by Airflow
    cd workspace
    mkdir -p ./dags ./logs ./plugins ./config ./training_runs # Have to create manually to avoid permission issue.
  ```

* An docker image for deployment is built inside the Airflow container so it must be configured to use docker build command. Change the `/var/run/docker.sock` permission so that Airflow container can use it:
  ```sh
    chmod 777 /var/run/docker.sock
  ```
* Now run airflow server and mlflow server using docker compose:
  ```sh
    echo -e "AIRFLOW_UID=$(id -u)" > .env
    docker compose up
  ```
Now the Airflow container is running in the local machine
### Setup remote servers
A small EC2 instance is used for running mlflow server using its docker image. The instance should be associated with an Elastic IP and expose the port (default 5000) to which mlflow server is listening. Remember to set host and timeout options:
  ```sh
    sudo docker run -p 5000:5000 --name mlflow_server ghcr.io/mlflow/mlflow:v2.3.2 mlflow server --host 0.0.0.0 --gunicorn-opts --timeout=600
    # If the timeout limit is small, downlading large artifacts can raise errors.
  ```
ECS fargate is used for serving the best mlflow model from registry to obtain endpoint urls with zero downtime compared to the solution in my [previous repo](https://github.com/phandaiduonghcb/mlops). Please refer to json files in `./ecs` to learn more about configuration I used for the deployment process. A load balancer is used to assign static URL for the endpoint served by the deployment container.
<!-- LICENSE -->
## License

Distributed under the MIT License. See `LICENSE.txt` for more information.

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- CONTACT -->
## Contact

Phan Dai Duong - phandaiduonghcb@gmail.com

Project Link: [https://github.com/phandaiduonghcb/local_mlops](https://github.com/phandaiduonghcb/local_mlops)

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- ACKNOWLEDGMENTS -->
<!-- ## Acknowledgments

* []()
* []()
* []() -->

<!-- <p align="right">(<a href="#readme-top">back to top</a>)</p> -->



<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[contributors-shield]: https://img.shields.io/github/contributors/phandaiduonghcb/local_mlops.svg?style=for-the-badge
[contributors-url]: https://github.com/phandaiduonghcb/local_mlops/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/phandaiduonghcb/local_mlops.svg?style=for-the-badge
[forks-url]: https://github.com/phandaiduonghcb/local_mlops/network/members
[stars-shield]: https://img.shields.io/github/stars/phandaiduonghcb/local_mlops.svg?style=for-the-badge
[stars-url]: https://github.com/phandaiduonghcb/local_mlops/stargazers
[issues-shield]: https://img.shields.io/github/issues/phandaiduonghcb/local_mlops.svg?style=for-the-badge
[issues-url]: https://github.com/phandaiduonghcb/local_mlops/issues
[license-shield]: https://img.shields.io/github/license/phandaiduonghcb/local_mlops.svg?style=for-the-badge
[license-url]: https://github.com/phandaiduonghcb/local_mlops/blob/master/LICENSE.txt
[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://linkedin.com/in/phandaiduonghcb
[product-screenshot]: images/screenshot.png
[Pytorch]: https://img.shields.io/badge/Pytorch-000000?style=for-the-badge&logo=Pytorchdotjs&logoColor=white
[Pytorch-url]: https://pytorch.org/
[Mlflow]: https://img.shields.io/badge/Mlflow-20232A?style=for-the-badge&logo=Mlflow&logoColor=61DAFB
[Mlflow-url]: https://mlflow.org/
[Airflow]: https://img.shields.io/badge/Airflow-35495E?style=for-the-badge&logo=Airflowdotjs&logoColor=4FC08D
[Airflow-url]: https://airflow.apache.org/
[DVC]: https://img.shields.io/badge/DVC-DD0031?style=for-the-badge&logo=DVC&logoColor=white
[DVC-url]: https://dvc.org/
[Docker]: https://img.shields.io/badge/Docker-4A4A55?style=for-the-badge&logo=Docker&logoColor=FF3E00
[Docker-url]: https://www.docker.com/
[Python]: https://img.shields.io/badge/Python-FF2D20?style=for-the-badge&logo=Python&logoColor=white
[Python-url]: https://www.python.org/
[AWS]: https://img.shields.io/badge/AWS-563D7C?style=for-the-badge&logo=AWS&logoColor=white
[AWS-url]: https://aws.amazon.com/
