/*
PowerShell and Performance Monitor (Perfmon) Counter
https://www.travisgan.com/2013/03/powershell-and-performance-monitor.html
*/

USE [db_monitor];
 
CREATE TABLE [dbo].[BaselinePerfmonCounters]
(
  [ID] [bigint] IDENTITY(1,1) NOT NULL PRIMARY KEY CLUSTERED,
  [Server] [nvarchar](50) NOT NULL,
  [TimeStamp] [datetime2](0) NOT NULL,
  [CounterGroup] [varchar](200) NULL,
  [CounterName] [varchar](200) NOT NULL,
  [CounterValue] [decimal](18, 5) NULL
);
GO
 
CREATE PROCEDURE [dbo].[usp_InsertPerfmonCounter]
(
  @xmlString varchar(max)
)
AS
SET NOCOUNT ON;
  
DECLARE @xml xml;
SET @xml = @xmlString;
  
INSERT INTO [dbo].[BaselinePerfmonCounters] ([TimeStamp], [Server], [CounterGroup], [CounterName], [CounterValue])
SELECT [Timestamp]
 , SUBSTRING([Path], 3, CHARINDEX('\',[Path],3)-3) AS [Server]
 , SUBSTRING([Path]
      , CHARINDEX('\',[Path],3)+1
      , LEN([Path]) - CHARINDEX('\',REVERSE([Path]))+1 - (CHARINDEX('\',[Path],3)+1)) AS [CounterGroup]
 , REVERSE(LEFT(REVERSE([Path]), CHARINDEX('\', REVERSE([Path]))-1)) AS [CounterName]
 , CAST([CookedValue] AS float) AS [CookedValue]
FROM
    (SELECT
        [property].value('(./text())[1]', 'VARCHAR(200)') AS [Value]
        , [property].value('@Name', 'VARCHAR(30)') AS [Attribute]
        , DENSE_RANK() OVER (ORDER BY [object]) AS [Sampling]
    FROM @xml.nodes('Objects/Object') AS mn ([object]) 
    CROSS APPLY mn.object.nodes('./Property') AS pn (property)) AS bp
PIVOT (MAX(value) FOR Attribute IN ([Timestamp], [Path], [CookedValue]) ) AS ap;
GO
