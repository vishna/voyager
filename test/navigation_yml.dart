const String navigation_yml = '''
---
'/home' :
  type: 'home'
  screen: HomeWidget
  title: "This is Home"
  fab: /other/thing
'/other/:title' :
  type: 'other'
  screen: OtherWidget
  title: "This is %{title}"
''';
