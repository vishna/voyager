const String navigation_yml = '''
---
'/home' :
  type: 'home'
  widget: HomeWidget
  title: "This is Home"
  fab: /other/thing
'/other/:title' :
  type: 'other'
  widget: OtherWidget
  title: "This is %{title}"
''';

const String navigation_yml_no_types = '''
---
'/home' :
  widget: HomeWidget
  title: "This is Home"
  fab: /other/thing
'/other/:title' :
  widget: OtherWidget
  title: "This is %{title}"
''';
