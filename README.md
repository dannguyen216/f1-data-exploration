# Formula 1 Data Exploration
## Summary
The files here are used to explore a Formula 1 dataset that contains information on various constructors, drivers and race results from 1950 to 2021. The Kaggle dataset can be found and downloaded using the link below:

__https://www.kaggle.com/rohanrao/formula-1-world-championship-1950-2020__

The primary goal of this project is to gain experience working with larger sets of data along with gaining familiarity with the Pandas library in Python. By exploring the dataset with SQL queries and a Jupyter Notebook file, we can note patterns in race performance along with useful visualizations that can help easily identify trends.

## Included Files
1. __``exploring_f1_data.sql``__: This file contains various SQL queries used to explore the Formula 1 dataset and understand the data/variables in each table along with aggregating the data and figuring out what questions I wanted to explore further in Python. \
\
The various ``.csv`` files that make up the dataset were imported using Microsoft SQL Server Management Studio, so note that various SQL commands will not line up with other RDBMS.

2. __``mclaren_hybrid_era.ipynb``__:
After getting acclimated with the dataset using SQL, this file explores the data using the Pandas library in Python with a specific focus on the McLaren Formula 1 team from the years 2014-2021. The Jupyter Notebook file takes a high-level look at the team's results throughout the years to see how the team has developed. Along with joining different dataframes and aggregating the data to note McLaren's average performance, the Matplotlib library (and to a lesser extent, the Seaborn library) was used to help visualize the data so that trends can be more clearly observed.\
\
The Python code in the file was written using __Python 3.9.7__.