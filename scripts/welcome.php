<?php
	$node = new stdClass();
	$node->type = 'page';
	node_object_prepare($node);

	$node->title    = 'Welcome to Boa';
	$node->promote  = 1;
	$node->sticky   = 1;
	$node->language = LANGUAGE_NONE;

	$body_text = 'Log in to the left with the username/password: ' . getenv('BOA_USER') . '/' . getenv('BOA_PW');
	$node->body[$node->language][0]['value']   = $body_text;
	$node->body[$node->language][0]['summary'] = $body_text;
	$node->body[$node->language][0]['format']  = 'filtered_html';

	$node->path = array('alias' => 'content/welcome');

	node_save($node);
?>
