formFields = new Array( 'title', 'docDate', 'extractedText' );

function sendUpdate(kkey, vvalue) {

    lockForm();
    $.ajax({ url: "dynamic",
             dataType: "xml",
             data: {action: "updateDocDetails", 
                    docid: $('#docid').text(),
                    kkey: kkey,
                    vvalue: vvalue,
                   },
             cache: false,
             type: "POST",
             success: function(data){
               if( $(data).find('error').text() ) {
                 alert("An error occured while updating the information.");
                 unlockForm(0);
               } else {
                 unlockForm(1);
               }
             }
           });

}

function moveTag(tagid, add_remove) {

    lockForm();
    id = tagid.replace(new RegExp("tagid_"),"");
    $.ajax({ url: "dynamic",
             dataType: "xml",
             data: {action: "moveTag", 
                    docid: $('#docid').text(),
                    tagid: id,
                    add_remove: add_remove,
                   },
             cache: false,
             type: "POST",
             success: function(data){
               if( $(data).find('error').text() ) {
                 alert("An error occured while updating the information.");
                 unlockForm(0);
               } else {
                 unlockForm(1);
               }
             }
           });
   // MOVE ME so this runs after success only **********************
   physicallyMoveTag(tagid);

}

function lockForm() {
  changeFormState(true);
}
function unlockForm(success) {
  changeFormState(false);
  if(success) {
    $('#saveAlert').show();
    $('#saveAlert').fadeOut(1000);
  }
}
function changeFormState(state) {
  for ( var key in formFields ) {
    if(state) {
      $('#'+formFields[key]).attr('disabled', 'disabled');
    } else {
      $('#'+formFields[key]).removeAttr('disabled');
    }
  }
}
function physicallyMoveTag(tagid) {

  // If tags parent is "available" then move to "selected"
  list = $('#'+tagid).parent().parent().attr("id");
  tr = document.getElementById(tagid);
  if(list=="available") {
    document.getElementById('available').getElementsByTagName('tbody')[0].removeChild(tr);
    document.getElementById('selected').getElementsByTagName('tbody')[0].appendChild(tr);
  } else {
    document.getElementById('selected').getElementsByTagName('tbody')[0].removeChild(tr);
    document.getElementById('available').getElementsByTagName('tbody')[0].appendChild(tr);
  }

  $("#available")
    .trigger("update")
    .trigger("appendCache")
    .trigger("sorton",[sorting]);
  $("#selected")
    .trigger("update")
    .trigger("appendCache")
    .trigger("sorton",[sorting]);

//  var tr = document.createElement("tr");
//  var id = document.createAttribute('id');
//  tr.setAttribute('id','tagid_'+tagid);
//  var e_tag = document.createElement("td");
//  e_tag.appendChild(document.createTextNode(tag));
//  tr.appendChild(e_tag);

}

$(document).ready(function() {

  for ( var key in formFields ) {
    $('#'+formFields[key]).change(function(){
      sendUpdate( $(this).attr('id'), $(this).val() );
    });
  }

  $('#delete').click( function() {
    var answer = confirm("Delete this document. Are you sure?");
    if (answer){
      $.ajax({ url: "dynamic",
             dataType: "xml",
             data: {action: "deletedoc", 
                    docid: $('#docid').text(),
                   },
             cache: false,
             type: "POST",
             success: function(data){
               document.location.href = "/";
             },
      });
    }
  });

});

