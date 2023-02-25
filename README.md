# prolog-car-race

![](https://github.com/Arrr-az/prolog-car-race/blob/main/README_gif.gif)

## What is it?
It's a simulation of a self-driving car with movements based on prolog. Developed as an academic activity for the course of Artificial Inteligence in UFES (Alegre) CS graduation.

The HTML+CSS+Javascript sections of the code were presented to us as it shows by the course professor (Jacson Rodrigues Correia da Silva), our job being the implementation of the 'decision-making' module, made with Prolog code.

In total, 7 versions of the prolog module were made, from v1 to v7-fa, each an updated version of the previous one. "v7-fa" being the best I could manage.

## How can you run it?
1. Download the .zip
2. Extract the files to your folder/directory of choice
3. Open a terminal in this same directory and type, for example, **swipl -s "v1.pl"** if you want to see the v1.pl module in action (not very interesting, might I add... it just moves the car forward)
4. Open your internet browser of choice and type **http://localhost:8080/** in the search bar. If all goes well, the simulation will start to run

## Ok, I tested one of them. How can I see the other prolog modules operating the car?
1. Go to the terminal and stop the Swipl process you just started with **CTRL + C** and then typing **e** (not **E**)
2. Say you wanna see v2.pl at it, type **swipl -s "v2.pl"** in the same terminal
3. Refresh your browser tab and *voilà*
WARNING: some browsers will keep running the previous prolog module even after you go through these steps. To fix this, clear your browser's recent cache (last hour or last 24 hours will do) and try again.

## Can I control the car using keyboard keys?
Sure thing! Just go to the "main.js" file, line 10, and set **const use_prolog = true;** to **const use_prolog = false;**
