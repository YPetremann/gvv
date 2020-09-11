-- 트리

local Table_to_str = require('modules.table_to_str')
local Util = require('modules.util')

local Tree = {}

--[[
트리 중첩 구조 :
parent_container
┖ children[#] (name없음. 루트의 경우 name = root_name)
   ┠ label_container
   ┃ ┠ vbar
   ┃ ┠ hbar
   ┃ ┠ folder_sprite (폴더인 경우만 존재)
   ┃ ┠ _gvv-mod_key_label (tree_data의 object또는 parent)
   ┃ ┠ equal_sign (값인 경우만 존재)
   ┃ ┖ _gvv-mod_key_value (값인 경우만 존재)
   ┖ content_container (폴더인 경우만 존재, 열기/닫기에 따라 visible 바꿈)
      ┠ extbar
      ┖ folder (하위 아이템의 새로운 parent_container)
--]]

-- tree_data keys : {parent, object, key, is_folder, is_root}

local key_type = function(key)
  if t == 'table' and type(obj.__self) == 'userdata' and obj.object_name then
    return obj.object_name
  else
    return type(key)
  end
end

--가지 그리기
local draw_branch = function(wrapper, key, noicon)
  wrapper.style.vertically_stretchable = false
  local label_container = wrapper.add{type = 'flow', name = 'label_container', direction = 'horizontal', style = 'hflow_gvv-mod'}
  label_container.style.height = 20

  local vbar = label_container.add{type = 'flow', name = 'vbar', direction = 'vertical', style = 'vflow_gvv-mod'}
  vbar.style.left_margin = 9
  vbar.style.width = 2
  vbar.style.vertically_stretchable = true
  vbar.add{type = 'empty-widget', name = 'part_top', style = 'branch_gvv-mod'}
  vbar.part_top.style.width = 2
  vbar.part_top.style.vertically_stretchable = true
  vbar.add{type = 'empty-widget', name = 'part_bottom', style = 'branch_gvv-mod'}
  vbar.part_bottom.style.width = 2
  vbar.part_bottom.style.vertically_stretchable = true
  local hbar = label_container.add{type = 'flow', name = 'hbar', direction = 'horizontal', style = 'hflow_gvv-mod'}
  if noicon then
    hbar.style.width = 30
  else
    hbar.style.width = 10
  end
  hbar.style.vertically_stretchable = true
  hbar.style.vertical_align = 'center'
  hbar.add{type = 'empty-widget', name = 'part', style = 'branch_gvv-mod'}
  hbar.part.style.height = 2
  hbar.part.style.horizontally_stretchable = true

  return label_container
end

--폴더인 경우 폴더그리기
local draw_folder = function(tree_data, parent_container, parent_label, folder_key, folder_name)
  local is_root = false
  local folder_wrap
  if not parent_label then
    is_root = true
    folder_wrap = parent_container.add{type = 'flow', name = folder_key, direction = 'vertical', style = 'vflow_gvv-mod'}
  else
    folder_wrap = parent_container.add{type = 'flow', direction = 'vertical', style = 'vflow_gvv-mod'}
  end


  local label_container = draw_branch(folder_wrap, folder_key)

  local sprite = label_container.add{type = 'sprite', name = 'folder_sprite', sprite = 'gvv-mod_folder-opened'}
  sprite.style.width = 20
  sprite.style.height = 20
  sprite.style.stretch_image_to_widget_size = true
  sprite.resize_to_sprite = false
  local key_label = label_container.add{type = 'button', name = '_gvv-mod_key_label', caption = folder_name,
    style = 'tree-item-folder_gvv-mod', mouse_button_filter = {'left', 'right'},
  }
  tree_data[#tree_data + 1] = {parent = parent_label, object = key_label, key = folder_key, is_folder = true, is_root = is_root}

  local content_container = folder_wrap.add{type = 'flow', name = 'content_container', direction = 'horizontal', style = 'hflow_gvv-mod'}
  local extbar = content_container.add{type = 'flow', name = 'extbar', direction = 'horizontal', style = 'hflow_gvv-mod'}
  extbar.add{type = 'empty-widget', name = 'part', style = 'branch_gvv-mod'}
  extbar.style.width = 11
  extbar.style.horizontal_align = 'right'
  extbar.part.style.left_margin = 9
  extbar.part.style.width = 2
  extbar.part.style.vertically_stretchable = true

  local folder = content_container.add{type = 'flow', name = 'folder', direction = 'vertical', style = 'vflow_gvv-mod'}
  folder.style.left_padding = 11
  return folder, key_label
end

--처음부터 그리기
Tree.draw_init = function(g, tab, mod_name_OR_luaobj, root_name)
  local tree_data, opened_folder_tree, parent_container
  local pc, tbl
  if tab == 'glob' then
    parent_container = g.gui.sub_globtree
    pc, tbl = pcall(function() return remote.call('__'..mod_name_OR_luaobj..'__gvv','global') end)
  elseif tab == 'prop' then
    parent_container = g.gui.sub_proptree
    pc, tbl = pcall(function() return mod_name_OR_luaobj end) --tbl은 prop에서 미사용
  elseif tab == 'gobj' then
    parent_container = g.gui.sub_gobjtree
    pc, tbl = pcall(function() return mod_name_OR_luaobj end) --tbl은 gobj에서 미사용
  end
  if not pc then error(tbl) return end
  if not g.data then g.data = {} end
  if not g.data.opened_data then g.data.opened_data = {} end
  if tab == 'glob' then
    if not g.data.tree_item_glob then g.data.tree_item_glob = {} end
    if not g.data.opened_data.globtree then g.data.opened_data.globtree = {} end
    if not g.data.opened_data.globtree[mod_name_OR_luaobj] then g.data.opened_data.globtree[mod_name_OR_luaobj] = {} end
    tree_data = g.data.tree_item_glob
    opened_folder_tree = g.data.opened_data.globtree[mod_name_OR_luaobj]
  elseif tab == 'prop' then
    if not g.data.tree_item_prop then g.data.tree_item_prop = {} end
    if not g.data.opened_data.proptree then g.data.opened_data.proptree = {} end
    if not g.data.opened_data.proptree[root_name] then g.data.opened_data.proptree[root_name] = {} end
    tree_data = g.data.tree_item_prop
    opened_folder_tree = g.data.opened_data.proptree[root_name]
  elseif tab == 'gobj' then
    if not g.data.tree_item_gobj then g.data.tree_item_gobj = {} end
    if not g.data.opened_data.gobjtree then g.data.opened_data.gobjtree = {} end
    if not g.data.opened_data.gobjtree[root_name] then g.data.opened_data.gobjtree[root_name] = {} end
    tree_data = g.data.tree_item_gobj
    opened_folder_tree = g.data.opened_data.gobjtree[root_name]
  end
  if table_size(parent_container.children) > 0 then
    if parent_container.children[1].name:match('^[*]') then
      parent_container.clear()
    end
  end
  if table_size(parent_container.children) > 0 then
    local root_elem = parent_container.children[1].label_container['_gvv-mod_key_label']
    local prev_opened_data
    if tab == 'glob' then
      local prev_mod_name = parent_container.children[1].name
      prev_opened_data = g.data.opened_data.globtree[prev_mod_name]
      for k in pairs(prev_opened_data) do prev_opened_data[k] = nil end
    elseif tab == 'prop' then
      local prev_root_name = parent_container.children[1].name
      prev_opened_data = g.data.opened_data.proptree[prev_root_name]
      for k in pairs(prev_opened_data) do prev_opened_data[k] = nil end
    elseif tab == 'gobj' then
      local prev_root_name = parent_container.children[1].name
      prev_opened_data = g.data.opened_data.gobjtree[prev_root_name]
      for k in pairs(prev_opened_data) do prev_opened_data[k] = nil end
    end
    Tree.save_opened_tree(tree_data, prev_opened_data, root_elem)
  end

  parent_container.clear()
  for k in pairs(tree_data) do tree_data[k] = nil end
  local folder, root
  if tab == 'glob' then
    folder, root = draw_folder(tree_data, parent_container, nil, root_name, 'remote.call("__[font=default-bold][color=green]'..mod_name_OR_luaobj..'[/color][/font]__gvv","global")')
    Tree.draw(g, tree_data, opened_folder_tree, tbl, folder, root, false)
  elseif tab == 'prop' or tab == 'gobj' then
    local props = Util.get_property_list(mod_name_OR_luaobj, true)
    if type(mod_name_OR_luaobj) == 'table' and type(mod_name_OR_luaobj.__self) == 'userdata' and mod_name_OR_luaobj.object_name then
      folder, root = draw_folder(tree_data, parent_container, nil, root_name, root_name..' ([color=blue]'..mod_name_OR_luaobj.object_name..'[/color])')
    else
      folder, root = draw_folder(tree_data, parent_container, nil, root_name, root_name..' ([color=1,0.3,0.3,1]'..type(mod_name_OR_luaobj)..'[/color])')
    end
    Tree.draw(g, tree_data, opened_folder_tree, props, folder, root, true)
  end
  folder.parent.extbar.visible = false
  folder.parent.parent.label_container.vbar.visible = false
  folder.parent.parent.label_container.hbar.part.style = 'branch-hide_gvv-mod'
end

--재귀 그리기
Tree.draw = function(g, tree_data, opened_folder_tree, tbl, parent_container, parent_label, prop_allowed)
  local s = {}
  local index = 0
  local table_keys = {}
  local item_name = ''
  local last_item, label_wrap, label_container, folder, label
  if not opened_folder_tree then return end
  for k, obj in pairs(tbl) do
    local t = type(obj)
    index = index + 1


    if prop_allowed and t == 'table' and type(obj.__self) == 'userdata' and obj.object_name then
      folder, label = draw_folder(tree_data, parent_container, parent_label, k, Table_to_str.to_richtext(k, true)..' ([color=blue]'..obj.object_name..'[/color])')
      if not opened_folder_tree or not opened_folder_tree[k] then
        parent_container.children[index].content_container.visible = false
        label.parent.folder_sprite.sprite = 'gvv-mod_folder-closed'
      else
        local props = Util.get_property_list(obj, true)
        Tree.draw(g, tree_data, opened_folder_tree[k], props, folder, label, prop_allowed)
      end
      table_keys[k] = true

    elseif t == 'table' and getmetatable(obj) == global.meta_data._nil_ then
      label_wrap = parent_container.add{type = 'flow', direction = 'vertical', style = 'vflow_gvv-mod'}
      label_container = draw_branch(label_wrap, k, true)
      last_item = label_container.add{type = 'button', name = '_gvv-mod_key_label', caption = Table_to_str.to_richtext(k, true),
        style = 'tree-item_gvv-mod', mouse_button_filter = {'right'},
      }
      tree_data[#tree_data + 1] = {parent = parent_label, object = last_item, key = k, is_folder = false}
      label_container.add{type = 'label', name = 'equal_sign', caption = ' = '}
      last_item = label_container.add{type = 'label', name = '_gvv-mod_key_value', caption = Table_to_str.to_richtext(nil)}

    elseif t == 'table' and getmetatable(obj) == global.meta_data._na_ then
      label_wrap = parent_container.add{type = 'flow', direction = 'vertical', style = 'vflow_gvv-mod'}
      if not g.show_na then label_wrap.visible = false end
      label_container = draw_branch(label_wrap, k, true)
      last_item = label_container.add{type = 'button', name = '_gvv-mod_key_label', caption = '[color=0.5,0.5,0.5,0.5]'..Table_to_str.to_richtext(k, true)..'[/color]',
        style = 'tree-item-na_gvv-mod', mouse_button_filter = {'right'},
      }
      tree_data[#tree_data + 1] = {parent = parent_label, object = last_item, key = k, is_folder = false}
      label_container.add{type = 'label', name = 'equal_sign', caption = ' = '}
      last_item = label_container.add{type = 'label', name = '_gvv-mod_key_value', caption = '[color=0.5,0,0,0.5]n/a[/color]'}

    elseif t == 'function' or t == 'table' and getmetatable(obj) == global.meta_data._function_ then
      label_wrap = parent_container.add{type = 'flow', direction = 'vertical', style = 'vflow_gvv-mod'}
      if prop_allowed then
        if not g.show_func then label_wrap.visible = false end
        label_container = draw_branch(label_wrap, k, true)
        last_item = label_container.add{type = 'button', name = '_gvv-mod_key_label', caption = '[color=0.5,0.5,0.5,0.5]'..Table_to_str.to_richtext(k, true)..'(...)[/color]',
          style = 'tree-item-func_gvv-mod', mouse_button_filter = {'right'},
        }
        tree_data[#tree_data + 1] = {parent = parent_label, object = last_item, key = k, is_folder = false}
      else
        label_container = draw_branch(label_wrap, k, true)
        last_item = label_container.add{type = 'button', name = '_gvv-mod_key_label', caption = Table_to_str.to_richtext(k, true),
          style = 'tree-item_gvv-mod', mouse_button_filter = {'right'},
        }
        tree_data[#tree_data + 1] = {parent = parent_label, object = last_item, key = k, is_folder = false}
        label_container.add{type = 'label', name = 'equal_sign', caption = ' = '}
        last_item = label_container.add{type = 'label', name = '_gvv-mod_key_value', caption = Table_to_str.to_richtext(obj)}
      end

    elseif t == 'table' and type(obj.__self) ~= 'userdata' and not obj.object_name then
      folder, label = draw_folder(tree_data, parent_container, parent_label, k, Table_to_str.to_richtext(k, true))
      if not opened_folder_tree or not opened_folder_tree[k] then
        parent_container.children[index].content_container.visible = false
        label.parent.folder_sprite.sprite = 'gvv-mod_folder-closed'
      else
        Tree.draw(g, tree_data, opened_folder_tree[k], tbl[k], folder, label, prop_allowed)
      end
      table_keys[k] = true

    else
      label_wrap = parent_container.add{type = 'flow', direction = 'vertical', style = 'vflow_gvv-mod'}
      label_container = draw_branch(label_wrap, k, true)
      last_item = label_container.add{type = 'button', name = '_gvv-mod_key_label', caption = Table_to_str.to_richtext(k, true),
        style = 'tree-item_gvv-mod', mouse_button_filter = {'right'},
      }
      tree_data[#tree_data + 1] = {parent = parent_label, object = last_item, key = k, is_folder = false}
      label_container.add{type = 'label', name = 'equal_sign', caption = ' = '}
      if t == 'table' and type(obj.__self) == 'userdata' and obj.object_name then
        last_item = label_container.add{type = 'button', name = '_gvv-mod_key_value', caption = Table_to_str.to_richtext(obj),
          style = 'tree-item-luaobj_gvv-mod', mouse_button_filter = {'right'},
        }
      else
        last_item = label_container.add{type = 'label', name = '_gvv-mod_key_value', caption = Table_to_str.to_richtext(obj)}
      end
    end


  end
  if opened_folder_tree then
    for k in pairs(opened_folder_tree) do
      if not table_keys[k] then opened_folder_tree[k] = nil end
    end
  end
  Tree.revision_line(parent_container)
end

--데이터에서 라벨개체의 트리정보 찾기
Tree.get_tree_data = function(tree_data, elem)
  for _, v in pairs(tree_data) do
    if v.object == elem then return v end
  end
  return nil
end

--라벨개체 경로 찾기
Tree.track_path = function(tree_data, item_label_elem, tree_path)
  local data = Tree.get_tree_data(tree_data, item_label_elem)
  table.insert(tree_path, 1, data.key)
  if data.parent and data.parent.valid then
    return Tree.track_path(tree_data, data.parent, tree_path)
  elseif data.is_root then
    return true, tree_path
  else
    return false, tree_path
  end
end

--라벨개체 풀경로 찾기
Tree.track_full_path = function(g, item_label_elem)
  local category = Tree.get_tree_category(item_label_elem)
  local tree_data
  if category == 'glob' then
    tree_data = g.data.tree_item_glob
  elseif category == 'prop' then
    tree_data = g.data.tree_item_prop
  elseif category == 'gobj' then
    tree_data = g.data.tree_item_gobj
  end
  local succ, tree_path = Tree.track_path(tree_data, item_label_elem, {})
  if succ then
    local index = tree_path[1]:match('^[(](%d+)[)] .+')
    if index then
      local front_tree_path = Util.deepcopytbl(g.data.docked_luaobj[index + 0].tree_path)
      table.remove(tree_path, 1)
      for k, v in pairs(tree_path) do table.insert(front_tree_path, v) end
      return front_tree_path
    else
      if category == 'gobj' then tree_path[1] = '*'..tree_path[1] end
      return tree_path
    end
  else
    error('Tree.track_path failed in Tree.track_full_path')
  end
end

--재귀 최상위 root_container찾기
local get_root_container
get_root_container = function(elem)
  if elem.parent then
    if elem.parent.name == '_gvv-mod_sub_globtree_' or elem.parent.name == '_gvv-mod_sub_proptree_' or elem.parent.name == '_gvv-mod_sub_gobjtree_' then
      return elem.parent
    else
      return get_root_container(elem.parent)
    end
  else
    return nil
  end
end

--아이템의 글로벌 변수찾기
Tree.get_global = function(elem)
  local root_container = get_root_container(elem)
  return remote.call('__'..root_container.children[1].name..'__gvv','global')
end

--아이템의 최상위 부모 아이템 찾기
Tree.get_top_parent = function(elem)
  local root_container = get_root_container(elem)
  return root_container.children[1].label_container['_gvv-mod_key_label']
end

--아이템의 트리 카테고리 찾기
Tree.get_tree_category = function(elem)
  local root_container = get_root_container(elem)
  if root_container.name == '_gvv-mod_sub_globtree_' then
    return 'glob'
  elseif root_container.name == '_gvv-mod_sub_proptree_' then
    return 'prop'
  elseif root_container.name == '_gvv-mod_sub_gobjtree_' then
    return 'gobj'
  end
end

--트리의 열린 폴더 정보 저장하기
Tree.save_opened_tree = function(tree_data, opened_folder_tree, elem)
  local folders = {}
  for _, v in pairs(tree_data) do
    if v.parent == elem and v.is_folder then
      if v.object.parent.parent.content_container.visible then
        folders[#folders + 1] = v.key
        opened_folder_tree[v.key] = {}
        Tree.save_opened_tree(tree_data, opened_folder_tree[v.key], v.object)
      end
    end
  end
end

--트리 경로의 값 얻기
Tree.get_tree_value = function(tree_path)
  local value
  if type(tree_path[1]) == 'string' then
    if tree_path[1]:match('^[*]()') then
      value = tree_path[1]:match('^[*](.*)')..''
      value = assert(loadstring('return '..value))()
    else
      value = remote.call('__'..tree_path[1]..'__gvv','global')
    end
  end
  for i = 2, #tree_path do
    value = value[tree_path[i]]
  end
  return value
end

--개체 트리 지우기
Tree.remove_prop_tree = function(g, index)
  local m
  for k, v in pairs(g.gui.sub_objlist.children) do
    m = v.name:match('^_gvv[-]mod_c_sub_obj_(%d+)$')
    if m then
      if m + 0 == index then
        v.destroy()
        g.data.docked_luaobj[index] = nil
        break
      end
    end
  end
  if g.gui.sub_proptree.children[1] then
    m = g.gui.sub_proptree.children[1].name:match('^[(](%d+)[)] .+')
    if m + 0 == index then
      g.gui.sub_proptree.clear()
    end
  end
end

-- 개체 등록
Tree.register_object = function(g, luaobj_elem)
  local tree_data
  local category = Tree.get_tree_category(luaobj_elem)
  if category == 'glob' then
    tree_data = g.data.tree_item_glob
  elseif category == 'prop' then
    tree_data = g.data.tree_item_prop
  elseif category == 'gobj' then
    tree_data = g.data.tree_item_gobj
  end
  if not g.data.docked_luaobj then g.data.docked_luaobj = {} end
  local data = Tree.get_tree_data(tree_data, luaobj_elem)
  local succ, tree_path = Tree.track_path(tree_data, luaobj_elem, {})
  local obj = Tree.get_tree_value(tree_path)
  if not succ then
    error('Tree.track_path failed in Tree.register_object')
  end
  if type(obj) == 'table' and type(obj.__self) == 'userdata' and obj.object_name then
    local pc, ret = pcall(function() return obj.valid end)
    if pc and not ret then
      error(luaobj_elem.caption..'('..obj.object_name..') object is not there anymore.')
    end
  else
    error(luaobj_elem.caption..'('..obj.object_name..') object is not there anymore.')
  end
  local already_exist = false
  local index
  for k, v in pairs(g.data.docked_luaobj) do
    if Util.table_shallow_compare(tree_path, v.tree_path) then
      already_exist = true
      index = k
      break
    end
  end
  if not already_exist then
    index = #g.data.docked_luaobj + 1
    g.data.docked_luaobj[index] = {
      index = index,
      luaobj = obj,
      key = data.key,
      tree_path = tree_path,
    }

    local sub_objlist = g.gui.sub_objlist
    local caption = '('..tostring(index)..') '..Table_to_str.to_luaon(data.key, true)
    local btn = sub_objlist.add{type = 'button', caption = caption, name = '_gvv-mod_c_sub_obj_'..tostring(index), mouse_button_filter = {'left', 'right'}, style = 'c_sub_mod_gvv-mod', tooltip = {"",{"gvv-mod.obj-list-tooltip"},'\n',Table_to_str.path_to_lua_prop_path(tree_path)}}
  end

  g.gui.tabpane.selected_tab_index = 3
  g.gui.chk_show_na.visible = true
  g.gui.chk_show_func.visible = true

  Tree.draw_proptree(g, index)
end

local valid = function(obj)
  local pc, ret = pcall(function() return obj.valid end)
  if not pc then return true
  else return ret
  end
end

-- 모드의 글로벌 트리 그리기
Tree.draw_globtree = function(g, mod_name)
  Tree.draw_init(g, 'glob', mod_name, mod_name)
end

-- 개체의 프로퍼티 트리 그리기
Tree.draw_proptree = function(g, dock_index)
  local data = g.data.docked_luaobj[dock_index]

  local obj = Tree.get_tree_value(data.tree_path)
  if type(obj) == 'table' and type(obj.__self) == 'userdata' and obj.object_name and valid(obj) then
  else
    local name = obj.object_name
    if not name then name = 'LuaObject' end
    error('That '..name..' is not there anymore.\n(index) path = '..root_name)
    return
  end
  data.luaobj = obj

  Tree.draw_init(g, 'prop', obj, '('..tostring(dock_index)..') '..Table_to_str.path_to_lua_prop_path(data.tree_path))
end

-- 글로벌 개체의 글로벌 트리 그리기
Tree.draw_gobjtree = function(g, gobj_name)
  local gobj = assert(loadstring('return '..gobj_name))()
  Tree.draw_init(g, 'gobj', gobj, gobj_name)
end

-- gvv 창을 닫을 때 저장하기
Tree.save_on_quit = function(g)
  if table_size(g.gui.sub_globtree.children) > 0 then
    local top = g.gui.sub_globtree.children[1]
    if not top.name:match('^[*]') then
      local opened_data = g.data.opened_data.globtree[top.name]
      for k in pairs(opened_data) do opened_data[k] = nil end
      Tree.save_opened_tree(g.data.tree_item_glob, opened_data, top.label_container['_gvv-mod_key_label'])
    end
  end
  if table_size(g.gui.sub_proptree.children) > 0 then
    local top = g.gui.sub_proptree.children[1]
    if not top.name:match('^[*]') then
      local opened_data = g.data.opened_data.proptree[top.name]
      for k in pairs(opened_data) do opened_data[k] = nil end
      Tree.save_opened_tree(g.data.tree_item_prop, opened_data, top.label_container['_gvv-mod_key_label'])
    end
  end
end

-- 트리 아이템 감추거나 보이기
Tree.set_visible_item = function(itemstyle, elem, state)
  if itemstyle == 'na' then
    Tree.set_visible_na(elem, state)
  elseif itemstyle == 'func' then
    Tree.set_visible_func(elem, state)
  end
  Tree.revision_line(elem)
end

-- show_na 감추거나 보이기
Tree.set_visible_na = function(parent_container, state)
  for _, container in pairs(parent_container.children) do
    if container.valid then
      if container.label_container then
        if container.label_container['_gvv-mod_key_label'].style.name == 'tree-item-na_gvv-mod' then
          container.visible = state
        end
      end
      if container.content_container then
        Tree.set_visible_na(container.content_container.folder, state)
      end
    end
  end
end

-- show_func 감추거나 보이기
Tree.set_visible_func = function(parent_container, state)
  for _, container in pairs(parent_container.children) do
    if container.valid then
      if container.label_container then
        if container.label_container['_gvv-mod_key_label'].style.name == 'tree-item-func_gvv-mod' then
          container.visible = state
        end
      end
      if container.content_container then
        Tree.set_visible_func(container.content_container.folder, state)
      end
    end
  end
end

-- 선 다시 그리기
Tree.revision_line = function(parent_container)
  local last_visible_index = 0
  for index, container in ipairs(parent_container.children) do
    if container.valid then
      if container.label_container then
        if container.visible then
          last_visible_index = index
          container.label_container.vbar.part_bottom.style = 'branch_gvv-mod'
          if container.content_container then
            container.content_container.extbar.part.style = 'branch_gvv-mod'
            Tree.revision_line(container.content_container.folder)
          end
        end
      end
    end
  end
  if last_visible_index > 0 then
    local last_container = parent_container.children[last_visible_index]
    last_container.label_container.vbar.part_bottom.style = 'branch-hide_gvv-mod'
    if last_container.content_container then
      last_container.content_container.extbar.part.style = 'branch-hide_gvv-mod'
    end
  end
end

Tree.ignore_in_help_page = function(g, elem)
  if elem.parent and elem.parent == g.gui.sub_helppanel then
    return true
  elseif elem.parent and elem.parent.valid then
    return Tree.ignore_in_help_page(g, elem.parent)
  else
    return false
  end
end

return Tree
