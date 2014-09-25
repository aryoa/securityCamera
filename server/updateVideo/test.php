<?php
	$filename = "/home/ryo/develop/movies/output01.MOV";
	$fileIndex = substr($filename, -5, 1);
	print  "fileIndex is $fileIndex\n";
	$rm_fileIndex = $fileIndex+1;
	if ($rm_fileIndex == 6){
		$rm_fileIndex = 1;
	}
	$rm_filename = str_replace($fileIndex, $rm_fileIndex , $filename);
	print "rm_filename is $rm_filename\n";
	if (file_exists($rm_filename)){
		unlink($rm_filename);
	}


?>

