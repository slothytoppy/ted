package renderer

/*
  Model($T) with methods -> update, render
  update needs to be able to modify the Model but it also needs to have access to events like keyboard events, quit events, etc
  render needs to not be able to modify the model but solely be responsible for turning the Models data into something renderable
  this renderable content would then be rendered by the main renderer
  or the renderer is responsible for messing with ncurses, moving the cursor, updating the screen and all that
  should i have something like editor.run(Model($T)) where i have my editors update and render functions that call out to the models update and render functions but it can do some special things like 
  only rendering x ticks where each tick is some amount of miliseconds/nanoseconds, or to take in some events like CursorChange, ClearScreen, RefreshScreen, etc

  or i could have a "main" renderer and updater where the updater gives you a event and it returns the Model and a new event, the renderer can take in events but it only cares about Renderer events

  editor.update and editor.render where both take in an Event but only editor.update can "produce" them
  how are Events produced? through key events like say you can set up "quit messages" for control+q and this triggers a Quit message which causes your app to well quit, Events can also be produced by your own Update functions since they return an Event
*/

/*
 proposal: editor has Update and Render methods, by default they do some thing but if you go into say the file viewer, they will call different things

 how to handle modes like insert and normal mode? all they really need are different keymaps so you can switch that out but how i hold the keymaps? i expect to have a kind of linear growth for keymaps and modes
 are keymaps global? for now; should they be? not at all but i dont want to be recreating keymaps if i switch from normal to insert mode
 
 */
