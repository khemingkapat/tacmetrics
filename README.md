# **TacMetrics: Systematic Toolkit for FPS Playstyle Evaluation**

## **Project Goal**

**TacMetrics** is a comprehensive data analysis framework built to provide objective, quantifiable metrics for evaluating competitive tactical First-Person Shooter (FPS) game playstyles (e.g., CS:GO, CS2, Valorant, etc.).  
Moving beyond basic statistics, this toolkit aims to systematically measure core tactical elements like team cohesion, movement efficiency, and territorial control for game analysts, making the core logic adaptable across any game that provides high-fidelity location data.

## **Technology Stack & Architecture**

This project adopts a high-performance, polyglot architecture to handle large, tick-by-tick game data efficiently.

* **Primary Backend/Performance:** **JuliaLang** for computationally heavy processing and metric generation (clustering, path decomposition).  
* **Data Processing/Ingestion:** **Python** (using libraries like awpy, demoparser2, and pandas) for initial demo parsing, data cleaning, and handling the interface with the Julia analysis module. *(Note: The Python parser must be adapted based on the target game's data format).*  
* **Visualization/Frontend:** A dashboard built using Streamlit or similar Python tools to visualize the metric results and interactive maps.  

## **Getting Started**

### **1\. Prerequisites**

* Julia (Version 1.8+)  
* Python (Version 3.11+)  
* A Demo File or equivalent spatial data file from your target FPS game.

### **2\. Setup (Using Nix/Flake)**

This repository uses Nix flakes for a reproducible environment that includes Python, Julia, and necessary dependencies.  
\# Enter the reproducible development shell (includes Julia and Python setup)  
```
nix develop
```
### **3\. Demo Parsing (Python)**

Use the provided script to extract data from a CS demo file into Parquet format, which is easier to work with in Julia. If using a different game (e.g., Valorant), this script must be replaced with the appropriate parser for that game's data format.  
\# Example usage (for CS-based demos):  
\# Create a folder called 'your-match' containing parquet files  
```
python parse_demo.py /path/to/your/match.dem --to_parquet true
```
### **4\. Running Julia Analysis (Manual Test)**

You can run the core Julia logic in the Pluto notebook for development:  
\# Start the Julia environment and the notebook server 
```
rj # (Custom alias defined in flake.nix shellHook)  
julia --project=. notebooks/notebook.jl
```
## **Contribution & Branching Strategy (Solo Project)**

This project uses a simple **Feature Branching** strategy for development, which helps keep the main codebase clean and stable.

### **Branch Naming**

All new work (based on a User Story or task) must start on a new branch derived from main.

| Type | Prefix | Example |
| :---- | :---- | :---- |
| **New Feature** | feature/ | feature/dynamic-grouping-logic |
| **Bug Fix** | fix/ | fix/julia-pycall-bug |

### **Workflow**

1. **Start New Work:** Always pull the latest changes from main before starting a new branch.
```
   git checkout main  
   git pull origin main  
   git checkout -b feature/new-feature-name
```
2. **Commit:** Work on your new feature and commit changes often.  
3. **Merge to Main:** When the feature is complete, tested, and ready, merge it back into main.
```  
   # Ensure you are on the feature branch  
   git checkout main  
   git merge feature/new-feature-name   
   git push origin main
```
4. **Clean Up:** After the feature is successfully merged to main, **always delete the feature branch** to keep the repository history clean.
```
   git branch \-d feature/new-feature-name         # Delete local branch  
   git push origin \--delete feature/new-feature-name # Delete remote branch
```

