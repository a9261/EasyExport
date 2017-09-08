# EasyExport
EasyExport is for SQL Server transform New version to Old version script 
# A known issued
1. If source database has enable new feature like Temporal Tables or In-memory Table. Transfer will fail . because the old version SQL Server unsupported
2. Because SQL Server scripter limit. when you export Full-text catalog. you need manually enable Full-text column on table
# Enviroment Requirement
Becuase this script will use **bcp** and **SMO**. You need install **SQL Server Management Studio** before start use this script 

# Release note
2017/09/08
1.Fix script cannot transfer database to SQL Server 2008 R2.
2.Fix target DbName not use at create database statement

2017/09/07

1.Fix script not generator Synonyms. 
2.Fix some powershell cannot read config.json
# How to Use 
**Step 1. Setting config.json**
![Setting Config](Step1_SettingConfig.png)
**Step 2. Execute script choose target SQL Server version**
![Setting Config](Step2_SettingTargetServerVersion.png)
**Step 3. Choose transfer method**
![Setting Config](Step3_ChooseTransferMethod.png)