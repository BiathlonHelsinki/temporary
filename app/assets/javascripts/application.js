// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require foundation
//= require jquery_nested_form
//= require moment 
//= require fullcalendar
//= require stacktable.min
//= require jquery.infinitescroll
//= require masonry.pkgd.min
//= require imagesloaded.pkgd.min
//= require jquery.mentionable
//= require jquery.scrollTo.min
  
function getContent(){
  var div_val=document.getElementById("comment_input").innerHTML;
          document.getElementById("comment_input_textarea").value =div_val;
      if(div_val==''){
  
      return false;
      //empty form will not be submit. You can also alert this message like this. alert(blahblah);
    }
}
function getContentEmptyOK(){
  var div_val=document.getElementById("comment_input").innerHTML;
          document.getElementById("comment_input_textarea").value =div_val;

}
    
$(function(){ 
  
  $(document).foundation();

 });
