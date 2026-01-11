/-
  TodoMVC View Layer

  This module provides an abstract view/rendering layer for TodoMVC.
  The view is modeled as a pure function from state to a representation
  of the UI (HTML-like structure).
-/

import TuxedoMVC.TodoMVC.Spec
import TuxedoMVC.TodoMVC.App
import TuxedoMVC.Coalgebra

namespace TodoMVC.View

open TodoMVC.Spec
open TodoMVC.App

/-! ## Abstract HTML Representation -/

/-- Attributes for HTML elements -/
structure Attr where
  name : String
  value : String
  deriving DecidableEq, Repr

/-- Abstract HTML tree representation -/
inductive Html where
  | text : String → Html
  | element : String → List Attr → List Html → Html
  | empty : Html
  deriving Repr

namespace Html

/-- Create a text node -/
def txt (s : String) : Html := .text s

/-- Create an element with children -/
def el (tag : String) (attrs : List Attr) (children : List Html) : Html :=
  .element tag attrs children

/-- Common element constructors -/
def div (attrs : List Attr) (children : List Html) : Html := el "div" attrs children
def span (attrs : List Attr) (children : List Html) : Html := el "span" attrs children
def ul (attrs : List Attr) (children : List Html) : Html := el "ul" attrs children
def li (attrs : List Attr) (children : List Html) : Html := el "li" attrs children
def button (attrs : List Attr) (children : List Html) : Html := el "button" attrs children
def label (attrs : List Attr) (children : List Html) : Html := el "label" attrs children
def input (attrs : List Attr) : Html := el "input" attrs []
def h1 (attrs : List Attr) (children : List Html) : Html := el "h1" attrs children
def header (attrs : List Attr) (children : List Html) : Html := el "header" attrs children
def section_ (attrs : List Attr) (children : List Html) : Html := el "section" attrs children
def footer (attrs : List Attr) (children : List Html) : Html := el "footer" attrs children
def a (attrs : List Attr) (children : List Html) : Html := el "a" attrs children
def strong (attrs : List Attr) (children : List Html) : Html := el "strong" attrs children

/-- Common attribute constructors -/
def class_ (name : String) : Attr := ⟨"class", name⟩
def id_ (name : String) : Attr := ⟨"id", name⟩
def type_ (t : String) : Attr := ⟨"type", t⟩
def placeholder_ (text : String) : Attr := ⟨"placeholder", text⟩
def checked_ (b : Bool) : Attr := ⟨"checked", if b then "true" else "false"⟩
def value_ (v : String) : Attr := ⟨"value", v⟩

/-- Escape HTML special characters -/
def escapeHtml (s : String) : String :=
  s.replace "&" "&amp;"
   |>.replace "<" "&lt;"
   |>.replace ">" "&gt;"
   |>.replace "\"" "&quot;"
   |>.replace "'" "&#39;"

/-- Convert an attribute to a string -/
def attrToString (attr : Attr) : String :=
  s!"{attr.name}=\"{escapeHtml attr.value}\""

/-- Convert Html AST to an HTML string -/
partial def toString : Html → String
  | .text s => escapeHtml s
  | .empty => ""
  | .element tag attrs children =>
      let attrsStr := match attrs with
        | [] => ""
        | _ => " " ++ String.intercalate " " (attrs.map attrToString)
      let childrenStr := String.join (children.map toString)
      if children.isEmpty && tag == "input" then
        s!"<{tag}{attrsStr}>"
      else if children.isEmpty then
        s!"<{tag}{attrsStr}></{tag}>"
      else
        s!"<{tag}{attrsStr}>{childrenStr}</{tag}>"

end Html

/-! ## View Model -/

/-- The view model extracts relevant information for rendering -/
structure ViewModel where
  items : List TodoItem
  filter : Option Filter
  activeCount : Nat
  completedCount : Nat
  inputValue : String
  deriving Repr

/-- Convert TodoState to ViewModel -/
def toViewModel (s : TodoState) : ViewModel := {
  items := s.visibleItems
  filter := s.selectedFilter
  activeCount := s.numUnchecked
  completedCount := s.numChecked
  inputValue := s.pendingText
}

/-! ## Rendering Functions -/

/-- Render a single todo item -/
def renderItem (item : TodoItem) : Html :=
  let itemClass := if item.completed then "completed" else ""
  Html.li [Html.class_ itemClass] [
    Html.div [Html.class_ "view"] [
      Html.input [Html.type_ "checkbox", Html.checked_ item.completed],
      Html.label [] [Html.txt item.text],
      Html.button [Html.class_ "destroy"] []
    ]
  ]

/-- Render the list of items -/
def renderItems (items : List TodoItem) : Html :=
  Html.ul [Html.class_ "todo-list"]
    (items.map renderItem)

/-- Render the header with input field -/
def renderHeader (inputValue : String) : Html :=
  Html.header [Html.class_ "header"] [
    Html.h1 [] [Html.txt "todos"],
    Html.input [
      Html.class_ "new-todo",
      Html.placeholder_ "What needs to be done?",
      Html.value_ inputValue
    ]
  ]

/-- Render a filter link -/
def renderFilterLink (current : Option Filter) (target : Filter) : Html :=
  let isSelected := current == some target
  let className := if isSelected then "selected" else ""
  let text := match target with
    | .all => "All"
    | .active => "Active"
    | .completed => "Completed"
  Html.li [] [
    Html.a [Html.class_ className] [Html.txt text]
  ]

/-- Render the footer with filters and counts -/
def renderFooter (activeCount : Nat) (completedCount : Nat) (filter : Option Filter) : Html :=
  let itemText := if activeCount == 1 then "item" else "items"
  Html.footer [Html.class_ "footer"] [
    Html.span [Html.class_ "todo-count"] [
      Html.strong [] [Html.txt s!"{activeCount}"],
      Html.txt s!" {itemText} left"
    ],
    Html.ul [Html.class_ "filters"] [
      renderFilterLink filter .all,
      renderFilterLink filter .active,
      renderFilterLink filter .completed
    ],
    if completedCount > 0 then
      Html.button [Html.class_ "clear-completed"] [
        Html.txt "Clear completed"
      ]
    else
      Html.empty
  ]

/-- Render the main section -/
def renderMain (items : List TodoItem) : Html :=
  if items.isEmpty then
    Html.empty
  else
    Html.section_ [Html.class_ "main"] [
      Html.input [Html.type_ "checkbox", Html.class_ "toggle-all"],
      renderItems items
    ]

/-- Render the complete TodoMVC view -/
def render (s : TodoState) : Html :=
  let vm := toViewModel s
  let header := renderHeader vm.inputValue
  let main := renderMain vm.items
  let footer := if vm.items.isEmpty then
      Html.empty
    else
      renderFooter vm.activeCount vm.completedCount vm.filter
  Html.div [Html.class_ "todoapp"] [
    header,
    main,
    footer
  ]

/-! ## Observer -/

/-- The view as an observer function -/
def viewObserver : Coalgebra.Observer TodoState Html := ⟨render⟩

/-- The view model as an observer -/
def viewModelObserver : Coalgebra.Observer TodoState ViewModel := ⟨toViewModel⟩

end TodoMVC.View
