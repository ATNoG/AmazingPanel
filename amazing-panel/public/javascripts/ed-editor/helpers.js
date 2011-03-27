/**
  * Helper method for creating and showing a dialog
  */
function createDialog(title){
  var modal = $(".modal");
  title = $(".title-box", modal).html(title);
  modal.addClass("dialog-active");  
  return modal;
}

/**
  * Helper method to hide a dialog
  */
function hideDialog(){
  var modal = $(".modal");
  $(".modal-container").empty();
  modal.removeClass("dialog-active");
  modal.hide();  
}

$.extend({ 
  keys: function(obj){ 
    var a = []; 
    $.each(obj, function(i){ 
      a.push(i)
    });
    return a; 
    } 
  }
);
