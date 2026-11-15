USE [master]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XP_MD5_EncodeKeyVal]') and OBJECTPROPERTY(id, N'IsExtendedProc') = 1)
exec sp_dropextendedproc N'[dbo].[XP_MD5_EncodeKeyVal]'
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

exec sp_addextendedproc N'XP_MD5_EncodeKeyVal', N'WZ_MD5_MOD.dll'
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XP_MD5_CheckValue]') and OBJECTPROPERTY(id, N'IsExtendedProc') = 1)
exec sp_dropextendedproc N'[dbo].[XP_MD5_CheckValue]'
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

exec sp_addextendedproc N'XP_MD5_CheckValue', N'WZ_MD5_MOD.dll'
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

USE [MuOnline]
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SP_MD5_ENCODE_VALUE]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SP_MD5_ENCODE_VALUE]
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

CREATE PROCEDURE SP_MD5_ENCODE_VALUE 

	@btInStr		VARCHAR(10),
	@btInStrIndex		VARCHAR(10)

--RETURNS BINARY(16)
--Created By WebZen
--Adapted By [CzF]Deathway
AS  
BEGIN 
	DECLARE	@btOutVal	BINARY(16)

	EXEC master..XP_MD5_EncodeKeyVal @btInStr, @btInStrIndex, @btOutVal OUT
	UPDATE MEMB_INFO SET memb__pwd = @btOutVal WHERE memb___id = @btInStrIndex
	RETURN 	@btOutVal
END
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO




