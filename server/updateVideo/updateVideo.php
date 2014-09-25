<?php
	$old = umask(0);
	openlog("myScriptLog", LOG_PID | LOG_PERROR, LOG_LOCAL0);
	syslog(LOG_NOTICE, "log start\n");

	if (!isset($_FILES["movie"]["error"])){
		syslog(LOG_NOTICE, "update error is undefined" );	
                closelog();
                exit(1);
	}
	$upload_error = $_FILES["movie"]["error"];
	switch ($upload_error) {
		case UPLOAD_ERR_OK:
			syslog(LOG_NOTICE, "The uploaded OK" );
			break;
		case UPLOAD_ERR_INI_SIZE:
			syslog(LOG_NOTICE, "The uploaded file exceeds the upload_max_filesize directive in php.ini" );
			break;
		case UPLOAD_ERR_FORM_SIZE:
			syslog(LOG_NOTICE, "The uploaded file exceeds the MAX_FILE_SIZE directive that was specified in the HTML form" );
 			break;
		case UPLOAD_ERR_PARTIAL:
			syslog(LOG_NOTICE, "The uploaded file was only partially uploaded" );
  			break;
		case UPLOAD_ERR_NO_FILE:
			syslog(LOG_NOTICE, "No file was uploaded" );
			break;
		case UPLOAD_ERR_NO_TMP_DIR:
			syslog(LOG_NOTICE, "Missing a temporary folder" );
 			break;
		case UPLOAD_ERR_CANT_WRITE:
			syslog(LOG_NOTICE, "Failed to write file to disk" );
			break;
 		case UPLOAD_ERR_EXTENSION:
			syslog(LOG_NOTICE, "File upload stopped by extension" );
			break;
		default:
			syslog(LOG_NOTICE, "Unknown upload error" );
 			break;
	}
	if ($upload_error != UPLOAD_ERR_OK){
		closelog();
		exit(1);
	}
        $updir = "/var/www/updateVideo/videos";
        $filename = $_FILES['movie']['name'];
        $tmp_filename = $_FILES["movie"]["tmp_name"];

	syslog(LOG_NOTICE, "upload_error is $upload_error" );
	syslog(LOG_NOTICE, "tmp_filename is $tmp_filename");
	syslog(LOG_NOTICE, "filename is $filename");
	//is_uploaded_file でファイルがアップロードされたかどうか調べる
	 if (is_uploaded_file($_FILES["movie"]["tmp_name"])) {
		//move_uploaded_file を使って一時的な保存先から指定のフォルダに移動させる
		syslog(LOG_NOTICE, "upfilename is $updir/$filename");
		if (move_uploaded_file($_FILES["movie"]["tmp_name"], "$updir/$filename")) {
			syslog(LOG_NOTICE, "move_uploaded_file OK");
			$fileIndex = substr("$updir/$filename", -5, 1);
			syslog(LOG_NOTICE, "fileIndex is $fileIndex");
			$rm_fileIndex = $fileIndex+1;
		        if ($rm_fileIndex == 6){
        		        $rm_fileIndex = 1;
        		}
        		$rm_filename = str_replace($fileIndex, $rm_fileIndex , "$updir/$filename");
			syslog(LOG_NOTICE, "$rm_filename remove");
        		if (file_exists($rm_filename)){
                		unlink($rm_filename);
        		}
			$fp = fopen('/var/www/updateVideo/videos/index.txt', 'w');
			fwrite($fp, "$fileIndex");
			fclose($fp);

		 }else {
			syslog(LOG_NOTICE, "move_uploaded_file NG");
		}
	} else {
		syslog(LOG_NOTICE, "not select file");
	}
	closelog();
?>

