<script language="php">
///////////////////////////////////////////////////////////////////////////////
// OBM - File : document_index.php                                           //
//     - Desc : Document Index File                                          //
// 2003-08-21 Rande Mehdi                                                    //
///////////////////////////////////////////////////////////////////////////////
// $Id$ //
///////////////////////////////////////////////////////////////////////////////
// Actions              -- Parameter
// - index (default)    -- search fields  -- show the document search form
// - search             -- search fields  -- show the result set of search
///////////////////////////////////////////////////////////////////////////////

// run_query_repository_links (document_type ??)
// gestion des repertoires
// vues
// outil d'admin
// migration ???

$path = "..";
$module = "document";
$obminclude = getenv("OBM_INCLUDE_VAR");
$extra_css = "document.css";
if ($obminclude == "") $obminclude = "obminclude";
include("$obminclude/global.inc");
page_open(array("sess" => "OBM_Session", "auth" => $auth_class_name, "perm" => "OBM_Perm"));
include("$obminclude/global_pref.inc");
require("document_query.inc");
require("document_display.inc");

if ($action == "") $action = "index";
$document = get_param_document();
get_document_action();
$perm->check_permissions($module, $action);
if (! check_privacy($module, "Document", $action, $document["id"], $uid)) {
  $display["msg"] = display_err_msg($l_error_visibility);
  $action = "index";
} else {
  update_last_visit("document", $document["id"], $action);
}
page_close();

///////////////////////////////////////////////////////////////////////////////
// Main Program                                                              //
///////////////////////////////////////////////////////////////////////////////
if ($action == "ext_get_path") {
  require("document_js.inc");
  $display["detail"] = html_documents_tree($document, $ext_disp_file);
} elseif ($action == "accessfile") {
  if ($document["id"] > 0) {
    $doc_q = run_query_detail($document);
    if ($doc_q->num_rows() == 1) {
      dis_file($doc_q);
      exit();
    }
  } else {
    $display["msg"] .= display_err_msg("$l_no_document !");
  }  
} elseif ($action == "ext_get_ids") {
  $display["search"] = dis_document_search_form($document);
  if ($set_display == "yes") {
    $display["result"] = dis_document_search_list($document);
  } else {
    $display["msg"] .= display_info_msg($l_no_display);
  }

///////////////////////////////////////////////////////////////////////////////
// Normal calls
///////////////////////////////////////////////////////////////////////////////
} elseif ($action == "index" || $action == "") {
///////////////////////////////////////////////////////////////////////////////
  $display["search"] = dis_document_search_form($document);
  if ($set_display == "yes") {
    $display["result"] = dis_document_search_list($document);
  } else {
    $display["msg"] .= display_info_msg($l_no_display);
  }

} elseif ($action == "search")  {
///////////////////////////////////////////////////////////////////////////////
  $display["search"] = dis_document_search_form($document);
  $display["result"] = dis_document_search_list($document);
  
} elseif ($action == "new")  {
///////////////////////////////////////////////////////////////////////////////
  require("document_js.inc");
  $display["detail"] = dis_document_form($action, $document, "");
  
} elseif ($action == "new_repository")  {
///////////////////////////////////////////////////////////////////////////////
  require("document_js.inc");
  $display["detail"] = html_repository_form($action, $document);
  
} elseif ($action == "tree")  {
///////////////////////////////////////////////////////////////////////////////
  require("document_js.inc");
  $display["detail"] = html_documents_tree($document,"true");
  
} elseif ($action == "detailconsult")  {
///////////////////////////////////////////////////////////////////////////////
  if ($document["id"] > 0) {
    $doc_q = run_query_detail($document);
    if ($doc_q->num_rows() == 1) {
      $display["detailInfo"] = display_record_info($doc_q);
      $display["detail"] = html_document_consult($doc_q);
    } else {
      $display["msg"] .= display_err_msg("$l_no_document !");
    }
  }

} elseif ($action == "detailupdate")  {
///////////////////////////////////////////////////////////////////////////////
if ($document["id"] > 0) {
    $doc_q = run_query_detail($document);
    if ($doc_q->num_rows() == 1) {
      require("document_js.inc");
      $display["detailInfo"] = display_record_info($doc_q);
      $display["detail"] = dis_document_form($action, $document, $doc_q);
  } else {
      $display["msg"] .= display_err_msg($l_query_error . " - " . $doc_q->query . " !");
    }
  }

} elseif ($action == "insert")  {
///////////////////////////////////////////////////////////////////////////////
  if (check_data_form("", $document)) {
    $document["id"] = run_query_insert($document);
    if ($document["id"]) {
      $display["msg"] .= display_ok_msg($l_insert_ok);
    } else {
      $display["msg"] .= display_err_msg($l_insert_error." ".$err_msg);
    }    
    $display["search"] = dis_document_search_form($document);
    $display["result"] = dis_document_search_list($document);
  // Form data are not valid
  } else {
    require("document_js.inc");
    $display["msg"] = display_warn_msg($l_invalid_data . " : " . $err_msg);
    $display["detail"] = dis_document_form($action, $document, "");
  }

} elseif ($action == "insert_repository")  {
///////////////////////////////////////////////////////////////////////////////
  if (check_repository_data_form($document)) {
    $retour = run_query_insert_repository($document);
    if ($retour) {
      $display["msg"] .= display_ok_msg($l_insert_ok);
    } else {
      $display["msg"] .= display_err_msg($l_insert_error);
    }
    require("document_js.inc");    
    $display["detail"] = html_documents_tree($document,true);
  // Form data are not valid
  } else {
    require("document_js.inc");
    $display["msg"] = display_warn_msg($l_invalid_data . " : " . $err_msg);
    $display["detail"] = html_repository_form($action, $document);
  }

} elseif ($action == "update")  {
///////////////////////////////////////////////////////////////////////////////
  if (check_data_form($document["id"], $document)) {
    $retour = run_query_update($document["id"], $document);
    if ($retour) {
      $display["msg"] .= display_ok_msg($l_update_ok);
    } else {
      $display["msg"] .= display_err_msg($l_update_error."  ".$err_msg);
    }
    $doc_q = run_query_detail($document);
    $display["detailInfo"] .= display_record_info($doc_q);
    $display["detail"] = html_document_consult($doc_q);
  } else {
    require("document_js.inc");
    $display["msg"] = display_warn_msg($l_invalid_data . " : " . $err_msg);
    $display["detail"] = dis_document_form($action, $document, "");
  }

} elseif ($action == "check_delete")  {
///////////////////////////////////////////////////////////////////////////////
  require("document_js.inc");
  $display["detail"] = dis_check_links($document["id"]);

} elseif ($action == "delete")  {
///////////////////////////////////////////////////////////////////////////////
  $retour = run_query_delete($document["id"]);
  if ($retour) {
    $display["msg"] .= display_ok_msg($l_delete_ok);
  } else {
    $display["msg"] .= display_err_msg($l_delete_error);
  }
  $display["search"] = dis_document_search_form($document);
  $display["result"] = dis_document_search_list($document);

} elseif ($action == "folder_check_delete")  {
///////////////////////////////////////////////////////////////////////////////
  require("document_js.inc");
  $display["detail"] = dis_check_repository_links($document["id"]);

} elseif ($action == "admin")  {
///////////////////////////////////////////////////////////////////////////////
  require("document_js.inc");
  $display["detail"] = dis_admin_index();

} elseif ($action == "cat1_insert")  {
///////////////////////////////////////////////////////////////////////////////
  $retour = run_query_cat1_insert($document);
  if ($retour) {
    $display["msg"] .= display_ok_msg($l_cat1_insert_ok);
  } else {
    $display["msg"] .= display_err_msg($l_cat1_insert_error);
  }
  require("document_js.inc");
  $display["detail"] .= dis_admin_index();

} elseif ($action == "cat1_update")  {
///////////////////////////////////////////////////////////////////////////////
  $retour = run_query_cat1_update($document);
  if ($retour) {
    $display["msg"] .= display_ok_msg($l_cat1_update_ok);
  } else {
    $display["msg"] .= display_err_msg($l_cat1_update_error);
  }
  require("document_js.inc");
  $display["detail"] .= dis_admin_index();

} elseif ($action == "cat1_checklink")  {
///////////////////////////////////////////////////////////////////////////////
  $display["detail"] .= dis_cat1_links($document);

} elseif ($action == "cat1_delete")  {
///////////////////////////////////////////////////////////////////////////////
  $retour = run_query_cat1_delete($document["category1"]);
  if ($retour) {
    $display["msg"] .= display_ok_msg($l_cat1_delete_ok);
  } else {
    $display["msg"] .= display_err_msg($l_cat1_delete_error);
  }
  require("document_js.inc");
  $display["detail"] .= dis_admin_index();

} elseif ($action == "cat2_insert")  {
///////////////////////////////////////////////////////////////////////////////
  $retour = run_query_cat2_insert($document);
  if ($retour) {
    $display["msg"] .= display_ok_msg($l_cat2_insert_ok);
  } else {
    $display["msg"] .= display_err_msg($l_cat2_insert_error);
  }
  require("document_js.inc");
  $display["detail"] .= dis_admin_index();

} elseif ($action == "cat2_update")  {
///////////////////////////////////////////////////////////////////////////////
  $retour = run_query_cat2_update($document);
  if ($retour) {
    $display["msg"] .= display_ok_msg($l_cat2_update_ok);
  } else {
    $display["msg"] .= display_err_msg($l_cat2_update_error);
  }
  require("document_js.inc");
  $display["detail"] .= dis_admin_index();

} elseif ($action == "cat2_checklink")  {
///////////////////////////////////////////////////////////////////////////////
  $display["detail"] .= dis_cat2_links($document);

} elseif ($action == "cat2_delete")  {
///////////////////////////////////////////////////////////////////////////////
  $retour = run_query_cat2_delete($document["category2"]);
  if ($retour) {
    $display["msg"] .= display_ok_msg($l_cat2_delete_ok);
  } else {
    $display["msg"] .= display_err_msg($l_cat2_delete_error);
  }
  require("document_js.inc");
  $display["detail"] .= dis_admin_index();

} elseif ($action == "mime_insert")  {
///////////////////////////////////////////////////////////////////////////////
  $retour = run_query_mime_insert($document);
  if ($retour) {
    $display["msg"] .= display_ok_msg($l_mime_insert_ok);
  } else {
    $display["msg"] .= display_err_msg($l_mime_insert_error);
  }
  require("document_js.inc");
  $display["detail"] .= dis_admin_index();

} elseif ($action == "mime_update")  {
///////////////////////////////////////////////////////////////////////////////
  $retour = run_query_mime_update($document);
  if ($retour) {
    $display["msg"] .= display_ok_msg($l_mime_update_ok);
  } else {
    $display["msg"] .= display_err_msg($l_mime_update_error);
  }
  require("document_js.inc");
  $display["detail"] .= dis_admin_index();

} elseif ($action == "mime_checklink")  {
///////////////////////////////////////////////////////////////////////////////
  $display["detail"] .= dis_mime_links($document);

} elseif ($action == "mime_delete")  {
///////////////////////////////////////////////////////////////////////////////
  $retour = run_query_mime_delete($document["mime"]);
  if ($retour) {
    $display["msg"] .= display_ok_msg($l_mime_delete_ok);
  } else {
    $display["msg"] .= display_err_msg($l_mime_delete_error);
  }
  require("document_js.inc");
  $display["detail"] .= dis_admin_index();

}  elseif ($action == "display") {
///////////////////////////////////////////////////////////////////////////////
  $prefs = get_display_pref($auth->auth["uid"], "document", 1);
  $display["detail"] = dis_document_display_pref($prefs);

} else if ($action == "dispref_display") {
///////////////////////////////////////////////////////////////////////////////
  update_display_pref($entity, $fieldname, $fieldstatus);
  $prefs = get_display_pref($auth->auth["uid"], "document", 1);
  $display["detail"] = dis_document_display_pref($prefs);

} else if ($action == "dispref_level") {
///////////////////////////////////////////////////////////////////////////////
  update_display_pref($entity, $fieldname, $fieldstatus, $fieldorder);
  $prefs = get_display_pref($auth->auth["uid"], "document", 1);
  $display["detail"] = dis_document_display_pref($prefs);
}

///////////////////////////////////////////////////////////////////////////////
// Display
///////////////////////////////////////////////////////////////////////////////

$display["head"] = display_head($l_document);
if (! $document["popup"]) {
  $display["header"] = generate_menu($module, $section);
}
$display["end"] = display_end();

display_page($display);


///////////////////////////////////////////////////////////////////////////////
// Stores Company parameters transmited in $document hash
// returns : $document hash with parameters set
///////////////////////////////////////////////////////////////////////////////
function get_param_document() {
  global $tf_title, $tf_author, $tf_path,$tf_mime,$tf_filename,$tf_repository_path;
  global $tf_cat1, $tf_cat2, $tf_extension, $tf_mimetype, $tf_name;
  global $fi_file_name,$fi_file_size,$fi_file_type,$fi_file;
  global $sel_cat1, $sel_cat2,$sel_mime,$cb_privacy,$rd_kind,$tf_url;
  global $param_ext, $ext_action, $ext_title, $ext_url, $ext_id, $ext_target;
  global $param_document, $popup, $param_entity, $entity,$rd_file_update; 

  if (isset ($param_document)) $document["id"] = $param_document;
  if (isset ($param_entity)) $document["entity_id"] = $param_entity;
  if (isset ($entity)) $document["entity"] = $entity;
  if (isset($rd_file_update)) $document["file_update"] = $rd_file_update;
  if (isset ($tf_url)) $document["url"] = $tf_url;
  
  if (isset ($tf_title)) $document["title"] = $tf_title;
  if (isset ($tf_name)) $document["name"] = $tf_name; // repository
  if (isset ($tf_author)) $document["author"] = $tf_author;
  if (isset ($tf_path)) $document["path"] = format_path(trim($tf_path));
  if (isset ($tf_filename)) $document["filename"] = $tf_filename;

  if (isset ($rd_kind)) $document["kind"] = $rd_kind;
  if (isset ($fi_file_name)) $document["name"] = $fi_file_name;
  if (isset ($fi_file_size)) $document["size"] = $fi_file_size;
  if (isset ($fi_file_type)) $document["mime_file"] = $fi_file_type;
  if (isset ($fi_file)) $document["file"] = $fi_file;

    // External param
  if (isset ($popup)) $document["popup"] = $popup;
  if (isset ($ext_action)) $document["ext_action"] = $ext_action;
  if (isset ($ext_title)) $document["ext_title"] = $ext_title;
  if (isset ($ext_url)) $document["ext_url"] = $ext_url;
  if (isset ($ext_id)) $document["ext_id"] = $ext_id;
  if (isset ($ext_target)) $document["ext_target"] = $ext_target;

  
  if (isset ($tf_cat1)) $document["cat1_label"] = $tf_cat1;
  if (isset ($tf_cat2)) $document["cat2_label"] = $tf_cat2;
  if (isset ($tf_mime)) $document["mime_label"] = $tf_mime;
  if (isset ($tf_extension)) $document["extension"] = $tf_extension;
  if (isset ($tf_mimetype)) $document["mimetype"] = $tf_mimetype;

  if (isset ($sel_cat1)) $document["category1"] = $sel_cat1;
  if (isset ($sel_cat2)) $document["category2"] = $sel_cat2;
  if (isset ($sel_mime)) $document["mime"] = $sel_mime;

  if (isset ($cb_privacy)) $document["privacy"] = $cb_privacy;

  display_debug_param($document);

  return $document;
}


///////////////////////////////////////////////////////////////////////////////
//  Document Action 
///////////////////////////////////////////////////////////////////////////////
function get_document_action() {
  global $document, $actions, $path;
  global $l_header_tree, $l_header_find, $l_header_new, $l_header_consult;
  global $l_header_update,$l_header_delete;
  global $l_header_display,$l_header_admin,$l_header_new_repository;
  global $cright_read, $cright_write, $cright_read_admin, $cright_write_admin;


// Index  
  $actions["document"]["index"] = array (
    'Name'     => $l_header_find,
    'Url'      => "$path/document/document_index.php?action=index",
    'Right'    => $cright_read,
    'Condition'=> array ('all') 
                                    	 );

// Tree view
  $actions["document"]["tree"]  = array (
    'Name'     => $l_header_tree,
    'Url'      => "$path/document/document_index.php?action=tree",
    'Right'    => $cright_read,
    'Condition'=> array ('all') 
                                     		 );

// Search
  $actions["document"]["search"] = array (
    'Url'      => "$path/document/document_index.php?action=search",
    'Right'    => $cright_read,
    'Condition'=> array ('None') 
                                    	 );

// New
  $actions["document"]["new"] = array (
    'Name'     => $l_header_new,
    'Url'      => "$path/document/document_index.php?action=new",
    'Right'    => $cright_write,
    'Condition'=> array ('search','index','detailconsult','new_repository','insert','insert_repository', 'tree','update','admin','display') 
                                     );

// New Repository
  $actions["document"]["new_repository"] = array (
    'Name'     => $l_header_new_repository,
    'Url'      => "$path/document/document_index.php?action=new_repository",
    'Right'    => $cright_write,
    'Condition'=> array ('search','index','detailconsult','new','insert','insert_repository','update',
                         'tree','admin','display') 
                                     );

// Detail Consult
  $actions["document"]["detailconsult"]  = array (
    'Name'     => $l_header_consult,
    'Url'      => "$path/document/document_index.php?action=detailconsult&amp;param_document=".$document["id"]."",
    'Right'    => $cright_read,
    'Privacy'  => true,
    'Condition'=> array ('detailupdate') 
                                     		 );

// Access Document
  $actions["document"]["accessfile"]  = array (
    'Url'      => "$path/document/document_index.php?action=accessfile&amp;param_document=".$document["id"]."",
    'Right'    => $cright_read,
    'Privacy'  => true,
    'Condition'=> array ('None') 
                                     		 );

// Detail Update
  $actions["document"]["detailupdate"] = array (
    'Name'     => $l_header_update,
    'Url'      => "$path/document/document_index.php?action=detailupdate&amp;param_document=".$document["id"]."",
    'Right'    => $cright_write,
    'Privacy'  => true,
    'Condition'=> array ('detailconsult', 'update') 
                                     	      );
// Update
  $actions["document"]["update"] = array (
    'Url'      => "$path/document/document_index.php?action=update",
    'Right'    => $cright_write,
    'Privacy'  => true,
    'Condition'=> array ('None') 
                                     	      );

// CheckDelete
  $actions["document"]["check_delete"] = array (
    'Name'     => $l_header_delete,
    'Url'      => "$path/document/document_index.php?action=check_delete&amp;param_document=".$document["id"]."",
    'Right'    => $cright_write,
    'Privacy'  => true,
    'Condition'=> array ('detailconsult', 'update') 
                                     	      );

// Delete
  $actions["document"]["delete"] = array (
    'Url'      => "$path/document/document_index.php?action=delete",
    'Right'    => $cright_write,
    'Privacy'  => true,
    'Condition'=> array ('None') 
                                     	      );

// Folder Check Delete
  $actions["document"]["folder_check_delete"] = array (
    'Url'      => "$path/document/document_index.php?action=folder_check_delete&amp;param_document=".$document["id"]."",
    'Right'    => $cright_write,
    'Privacy'  => true,
    'Condition'=> array ('None')
                                     	      );

// Insert
  $actions["document"]["insert"] = array (
    'Url'      => "$path/document/document_index.php?action=insert",
    'Right'    => $cright_write,
    'Condition'=> array ('None') 
                                     	 );  

// Repository Insert
  $actions["document"]["insert_repository"] = array (
    'Url'      => "$path/document/document_index.php?action=insert_repository",
    'Right'    => $cright_write,
    'Condition'=> array ('None') 
                                     	 );  
// Admin
  $actions["document"]["admin"] = array (
    'Name'     => $l_header_admin,
    'Url'      => "$path/document/document_index.php?action=admin",
    'Right'    => $cright_read_admin,
    'Condition'=> array ('all') 
   					);

// Category Insert
  $actions["document"]["cat1_insert"] = array (
    'Url'      => "$path/document/document_index.php?action=cat1_insert",
    'Right'    => $cright_write_admin,
    'Condition'=> array ('None') 
                                     	     );

// Category Update
  $actions["document"]["cat1_update"] = array (
    'Url'      => "$path/document/document_index.php?action=cat1_update",
    'Right'    => $cright_write_admin,
    'Condition'=> array ('None') 
                                     	      );

// Category Check Link
  $actions["document"]["cat1_checklink"] = array (
    'Url'      => "$path/document/document_index.php?action=cat1_checklink",
    'Right'    => $cright_write_admin,
    'Condition'=> array ('None') 
                                     		);

// Category Delete
  $actions["document"]["cat1_delete"] = array (
    'Url'      => "$path/document/document_index.php?action=cat1_delete",
    'Right'    => $cright_write_admin,
    'Condition'=> array ('None') 
                                     	       );

// Category Insert
  $actions["document"]["cat2_insert"] = array (
    'Url'      => "$path/document/document_index.php?action=cat2_insert",
    'Right'    => $cright_write_admin,
    'Condition'=> array ('None') 
                                     	     );

// Category Update
  $actions["document"]["cat2_update"] = array (
    'Url'      => "$path/document/document_index.php?action=cat2_update",
    'Right'    => $cright_write_admin,
    'Condition'=> array ('None') 
                                     	      );

// Category Check Link
  $actions["document"]["cat2_checklink"] = array (
    'Url'      => "$path/document/document_index.php?action=cat2_checklink",
    'Right'    => $cright_write_admin,
    'Condition'=> array ('None') 
                                     		);

// Category Delete
  $actions["document"]["cat2_delete"] = array (
    'Url'      => "$path/document/document_index.php?action=cat2_delete",
    'Right'    => $cright_write_admin,
    'Condition'=> array ('None') 
                                     	       );

// Mime Insert
  $actions["document"]["mime_insert"] = array (
    'Url'      => "$path/document/document_index.php?action=mime_insert",
    'Right'    => $cright_write_admin,
    'Condition'=> array ('None') 
                                     	     );

// Mime Update
  $actions["document"]["mime_update"] = array (
    'Url'      => "$path/document/document_index.php?action=mime_update",
    'Right'    => $cright_write_admin,
    'Condition'=> array ('None') 
                                     	      );

// Mime Check Link
  $actions["document"]["mime_checklink"] = array (
    'Url'      => "$path/document/document_index.php?action=mime_checklink",
    'Right'    => $cright_write_admin,
    'Condition'=> array ('None') 
                                     		);

// Mime Delete
  $actions["document"]["mime_delete"] = array (
    'Url'      => "$path/document/document_index.php?action=mime_delete",
    'Right'    => $cright_write_admin,
    'Condition'=> array ('None') 
                                     	       );
  // Display
  $actions["document"]["display"] = array (
    'Name'     => $l_header_display,
    'Url'      => "$path/document/document_index.php?action=display",
    'Right'    => $cright_read,
    'Condition'=> array ('all') 
                                      	 );

// Display Preferences
  $actions["document"]["dispref_display"] = array (
    'Url'      => "$path/document/document_index.php?action=dispref_display",
    'Right'    => $cright_read,
    'Condition'=> array ('None') 
                                     		 );

// Display Level
  $actions["document"]["dispref_level"]  = array (
    'Url'      => "$path/document/document_index.php?action=dispref_level",
    'Right'    => $cright_read,
    'Condition'=> array ('None') 
                                     		 );

// External path view
  $actions["document"]["ext_get_path"]  = array (
    'Url'      => "$path/document/document_index.php?action=ext_get_path",
    'Right'    => $cright_read,
    'Condition'=> array ('None') 
                                     		 );

// External view
  $actions["document"]["ext_get_ids"]  = array (
    'Url'      => "$path/document/document_index.php?action=ext_get_ids",
    'Right'    => $cright_read,
    'Condition'=> array ('None') 
                                     		 );
}
