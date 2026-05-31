///|
using @respo_node {
  button,
  div,
  span,
  text_node,
  textarea,
  type DispatchFn,
  type RespoCommonError,
  type RespoEvent,
}

///|
using @css {type RespoStyle, respo_style}

///|
let app_store_key : String = "json-diff-ui"

///|
let display_flex : @css.CssDisplay = @css.CssDisplay::Flex

///|
let display_inline_block : @css.CssDisplay = @css.CssDisplay::InlineBlock

///|
let direction_row : @css.CssFlexDirection = @css.CssFlexDirection::Row

///|
let direction_column : @css.CssFlexDirection = @css.CssFlexDirection::Column

///|
let justify_space_between : @css.CssFlexJustifyContent = @css.CssFlexJustifyContent::SpaceBetween

///|
let align_center : @css.CssFlexAlignItems = @css.CssFlexAlignItems::Center

///|
let overflow_hidden : @css.CssOverflow = @css.CssOverflow::Hidden

///|
let border_solid : @css.CssBorderStyle = @css.CssBorderStyle::Solid

///|
enum GlobalEvent {}

///|
fn px(value : Float) -> @css.CssSize {
  @css.CssSize::Px(value)
}

///|
fn pct(value : Float) -> @css.CssSize {
  @css.CssSize::Percent(value)
}

///|
fn vh(value : Float) -> @css.CssSize {
  @css.CssSize::Vh(value)
}

///|
fn color(h : Int, s : Int, l : Int) -> @css.CssColor {
  @css.CssColor::Hsl(
    h.reinterpret_as_uint(),
    s.reinterpret_as_uint(),
    l.reinterpret_as_uint(),
  )
}

///|
fn compact_json(value : Json?) -> String {
  match value {
    None => "missing"
    Some(Json::Object(entries)) => if entries.length() == 0 {
      "{ }"
    } else {
      "{ \{entries.length()} }"
    }
    Some(Json::Array(items)) => if items.length() == 0 {
      "[ ]"
    } else {
      "[ \{items.length()} ]"
    }
    Some(Json::String(text)) => "\"\{text}\""
    Some(Json::Number(number, repr~)) => repr.unwrap_or(number.to_string())
    Some(Json::True) => "true"
    Some(Json::False) => "false"
    Some(Json::Null) => "null"
  }
}

///|
enum DiffStatus {
  Added
  Changed
  Removed
  Unchanged
} derive(Eq)

///|
struct Analysis {
  left : Json?
  right : Json?
  left_error : String?
  right_error : String?
  patch_count : Int
  changed_paths : Array[Array[AppPathSeg]]
}

///|
fn parse_json_text(text : String) -> Result[Json, String] {
  try @json.parse(text[:]) catch {
    err => Err(err.to_string())
  } noraise {
    value => Ok(value)
  }
}

///|
fn patch_segments_to_path(
  path : Array[@recollect.PathSegment],
) -> Array[AppPathSeg] {
  let segments : Array[AppPathSeg] = []
  for segment in path {
    match segment {
      Field(name) => segments.push(Field(name))
      Index(index) => segments.push(Index(index))
    }
  }
  segments
}

///|
fn path_has_prefix(
  path : Array[AppPathSeg],
  prefix : Array[AppPathSeg],
) -> Bool {
  if prefix.length() > path.length() {
    return false
  }
  for idx = 0; idx < prefix.length(); idx = idx + 1 {
    if path[idx] != prefix[idx] {
      return false
    }
  }
  true
}

///|
fn contains_exact_path(
  paths : Array[Array[AppPathSeg]],
  target : Array[AppPathSeg],
) -> Bool {
  let mut found = false
  for path in paths {
    if path == target {
      found = true
    }
  }
  found
}

///|
fn contains_descendant_path(
  paths : Array[Array[AppPathSeg]],
  target : Array[AppPathSeg],
) -> Bool {
  let mut found = false
  for path in paths {
    if path.length() > target.length() && path_has_prefix(path, target) {
      found = true
    }
  }
  found
}

///|
fn append_unique_path(
  paths : Array[Array[AppPathSeg]],
  target : Array[AppPathSeg],
) -> Unit {
  if !contains_exact_path(paths, target) {
    paths.push(target)
  }
}

///|
fn extend_path(
  path : Array[AppPathSeg],
  segment : AppPathSeg,
) -> Array[AppPathSeg] {
  let next = path.copy()
  next.push(segment)
  next
}

///|
fn analyze_store(store : Store) -> Analysis {
  let left_result = parse_json_text(store.left_text)
  let right_result = parse_json_text(store.right_text)
  match (left_result, right_result) {
    (Ok(left), Ok(right)) => {
      let changed_paths : Array[Array[AppPathSeg]] = []
      let patches = @recollect.diff_json(left, right)
      for patch in patches {
        match patch {
          Set(path~, ..) => {
            let next_path = patch_segments_to_path(path)
            append_unique_path(changed_paths, next_path)
          }
          Remove(path~) => {
            let next_path = patch_segments_to_path(path)
            append_unique_path(changed_paths, next_path)
          }
          Insert(path~, index~, ..) => {
            let parent_path = patch_segments_to_path(path)
            let item_path = extend_path(parent_path, Index(index))
            append_unique_path(changed_paths, parent_path)
            append_unique_path(changed_paths, item_path)
          }
          Delete(path~, index~) => {
            let parent_path = patch_segments_to_path(path)
            let item_path = extend_path(parent_path, Index(index))
            append_unique_path(changed_paths, parent_path)
            append_unique_path(changed_paths, item_path)
          }
          Move(path~, ..) => {
            let parent_path = patch_segments_to_path(path)
            append_unique_path(changed_paths, parent_path)
          }
        }
      }
      {
        left: Some(left),
        right: Some(right),
        left_error: None,
        right_error: None,
        patch_count: patches.length(),
        changed_paths,
      }
    }
    (Err(left_error), Ok(_)) =>
      {
        left: None,
        right: None,
        left_error: Some(left_error),
        right_error: None,
        patch_count: 0,
        changed_paths: [],
      }
    (Ok(_), Err(right_error)) =>
      {
        left: None,
        right: None,
        left_error: None,
        right_error: Some(right_error),
        patch_count: 0,
        changed_paths: [],
      }
    (Err(left_error), Err(right_error)) =>
      {
        left: None,
        right: None,
        left_error: Some(left_error),
        right_error: Some(right_error),
        patch_count: 0,
        changed_paths: [],
      }
  }
}

///|
fn object_keys(
  left : Map[String, Json]?,
  right : Map[String, Json]?,
) -> Array[String] {
  let keys : Array[String] = []
  if left is Some(left_entries) {
    for key, _ in left_entries {
      keys.push(key)
    }
  }
  if right is Some(right_entries) {
    for key, _ in right_entries {
      if !keys.contains(key) {
        keys.push(key)
      }
    }
  }
  keys
}

///|
fn path_status(
  path : Array[AppPathSeg],
  left : Json?,
  right : Json?,
  changed_paths : Array[Array[AppPathSeg]],
) -> DiffStatus {
  if left is None && right is Some(_) {
    return Added
  }
  if left is Some(_) && right is None {
    return Removed
  }
  if contains_exact_path(changed_paths, path) ||
    contains_descendant_path(changed_paths, path) {
    return Changed
  }
  Unchanged
}

///|
// Tag-style chip used on container rows only (not leaf nodes)
fn status_chip(status : DiffStatus) -> (String, RespoStyle) {
  match status {
    Added =>
      (
        "+ added",
        respo_style(
          color=color(208, 80, 20),
          background_color=color(208, 70, 90),
          padding_left=px(6),
          padding_right=px(6),
          padding_top=px(1),
          padding_bottom=px(1),
          border_radius=4.0,
          font_size=10,
          font_weight="600",
        ),
      )
    Removed =>
      (
        "− removed",
        respo_style(
          color=color(355, 72, 30),
          background_color=color(355, 70, 92),
          padding_left=px(6),
          padding_right=px(6),
          padding_top=px(1),
          padding_bottom=px(1),
          border_radius=4.0,
          font_size=10,
          font_weight="600",
        ),
      )
    Changed =>
      (
        "~ changed",
        respo_style(
          color=color(32, 82, 24),
          background_color=color(40, 88, 90),
          padding_left=px(6),
          padding_right=px(6),
          padding_top=px(1),
          padding_bottom=px(1),
          border_radius=4.0,
          font_size=10,
          font_weight="600",
        ),
      )
    Unchanged =>
      (
        "same",
        respo_style(
          color=color(210, 10, 40),
          background_color=color(210, 16, 93),
          padding_left=px(6),
          padding_right=px(6),
          padding_top=px(1),
          padding_bottom=px(1),
          border_radius=4.0,
          font_size=10,
        ),
      )
  }
}


///|
fn descendant_change_count(
  paths : Array[Array[AppPathSeg]],
  target : Array[AppPathSeg],
) -> Int {
  let mut total = 0
  for path in paths {
    if path.length() > target.length() && path_has_prefix(path, target) {
      total = total + 1
    }
  }
  total
}

///|
fn inline_value_box(
  text : String,
  background : @css.CssColor,
  foreground : @css.CssColor,
) -> @respo_node.RespoNode[ActionOp, GlobalEvent] {
  div(
    style=respo_style(
      display=display_inline_block,
      background_color=background,
      color=foreground,
      padding_left=px(6),
      padding_right=px(6),
      padding_top=px(3),
      padding_bottom=px(3),
      border_radius=6.0,
      font_family="Menlo, Monaco, monospace",
      font_size=11,
    ),
    [text_node(text)],
  )
}


///|
fn render_value_summary(
  status : DiffStatus,
  left : Json?,
  right : Json?,
) -> @respo_node.RespoNode[ActionOp, GlobalEvent] {
  match status {
    Unchanged =>
      span(
        style=respo_style(
          font_family="Menlo, Monaco, monospace",
          font_size=11,
          color=color(0, 0, 48),
        ),
        [text_node(compact_json(right))],
      )
    // Added: light blue box, no chip label
    Added =>
      inline_value_box(compact_json(right), color(208, 80, 92), color(208, 82, 20))
    // Removed: ghost — box visible but text fades into background
    Removed =>
      inline_value_box(compact_json(left), color(0, 0, 96), color(0, 0, 78))
    // Changed: old (red) → new (blue), no chip label needed
    Changed =>
      div(
        style=respo_style(
          display=display_flex,
          flex_direction=direction_row,
          align_items=align_center,
          gap=px(6),
        ),
        [
          inline_value_box(compact_json(left), color(355, 88, 90), color(355, 82, 22)),
          span(
            style=respo_style(font_size=12, font_weight="600", color=color(0, 0, 52)),
            [text_node("→")],
          ),
          inline_value_box(compact_json(right), color(208, 80, 92), color(208, 82, 20)),
        ],
      )
  }
}

///|
fn render_node(
  path : Array[AppPathSeg],
  label : String,
  left : Json?,
  right : Json?,
  analysis : Analysis,
  depth : Float,
  is_index~ : Bool = false,
) -> @respo_node.RespoNode[ActionOp, GlobalEvent] {
  let status = path_status(path, left, right, analysis.changed_paths)
  let has_exact_change = contains_exact_path(analysis.changed_paths, path)
  let descendant_changes = descendant_change_count(analysis.changed_paths, path)
  let can_expand = match (left, right) {
    (Some(Json::Object(_)), Some(Json::Object(_))) => true
    (Some(Json::Array(_)), Some(Json::Array(_))) => true
    (Some(Json::Object(_)), None) => true
    (None, Some(Json::Object(_))) => true
    (Some(Json::Array(_)), None) => true
    (None, Some(Json::Array(_))) => true
    _ => false
  }
  let container_inside_change = can_expand && descendant_changes > 0
  let (chip_text, chip_style) = status_chip(status)
  // Only color the row for direct changes; containers that merely contain changes stay white
  let row_background = if status == Added {
    color(130, 45, 96)
  } else if status == Removed {
    color(355, 70, 96)
  } else if has_exact_change {
    color(44, 85, 96)
  } else {
    color(0, 0, 100)
  }
  // Containers whose changes are only in descendants: mute label, hide chip/badge
  let is_muted_container = container_inside_change && !has_exact_change
  // Bracket indicator for container rows
  let bracket_char : String? = if can_expand {
    match (left, right) {
      (Some(Json::Object(_)), _) | (_, Some(Json::Object(_))) => Some("{")
      (Some(Json::Array(_)), _) | (_, Some(Json::Array(_))) => Some("[")
      _ => None
    }
  } else {
    None
  }
  let rows : Array[@respo_node.RespoNode[ActionOp, GlobalEvent]] = [
    div(
      style=respo_style(
        padding_left=px(depth * 18.0 + 12.0),
        border_bottom_color=color(0, 0, 92),
        border_bottom_width=px(1),
        border_bottom_style=border_solid,
      ),
      [
        div(
          style=respo_style(
            display=display_flex,
            flex_direction=direction_row,
            align_items=align_center,
            justify_content=justify_space_between,
            gap=px(8),
            width=pct(100),
            padding_left=px(8),
            padding_right=px(8),
            padding_top=px(5),
            padding_bottom=px(5),
            background_color=row_background,
            border_radius=6.0,
          ),
          [
            // Left column: key label (array-index gets a distinct badge)
            div(
              style=respo_style(
                display=display_flex,
                flex_direction=direction_row,
                align_items=align_center,
                width=pct(33),
              ),
              [
                if is_index {
                  // Positional index badge — visually distinct from real keys
                  span(
                    style=respo_style(
                      font_family="Menlo, Monaco, monospace",
                      font_size=10,
                      font_weight="500",
                      color=color(260, 28, 36),
                      background_color=color(260, 26, 94),
                      padding_left=px(5),
                      padding_right=px(5),
                      padding_top=px(1),
                      padding_bottom=px(1),
                      border_radius=4.0,
                    ),
                    [text_node(label)],
                  )
                } else {
                  span(
                    style=respo_style(
                      font_family="Menlo, Monaco, monospace",
                      font_size=12,
                      font_weight=if is_muted_container { "400" } else { "500" },
                      color=if is_muted_container {
                        color(0, 0, 60)
                      } else {
                        color(0, 0, 14)
                      },
                    ),
                    [text_node(label)],
                  )
                },
              ],
            ),
            // Right column: [container-chip] [bracket or leaf-value]
            // Chip shown only on container rows; leaf rows rely on colored value boxes
            div(
              style=respo_style(
                display=display_flex,
                flex_direction=direction_row,
                align_items=align_center,
                gap=px(8),
                width=pct(65),
              ),
              [
                if can_expand &&
                  (has_exact_change || status == Added || status == Removed) {
                  span(style=chip_style, [text_node(chip_text)])
                } else {
                  div([])
                },
                if can_expand {
                  match bracket_char {
                    Some(ch) =>
                      span(
                        style=respo_style(
                          font_family="Menlo, Monaco, monospace",
                          font_size=14,
                          font_weight="300",
                          color=if is_muted_container {
                            color(0, 0, 68)
                          } else {
                            color(0, 0, 32)
                          },
                        ),
                        [text_node(ch)],
                      )
                    None => div([])
                  }
                } else {
                  render_value_summary(status, left, right)
                },
              ],
            ),
          ],
        ),
      ],
    ),
  ]
  if can_expand {
    match (left, right) {
      (Some(Json::Object(left_entries)), Some(Json::Object(right_entries))) =>
        for key in object_keys(Some(left_entries), Some(right_entries)) {
          let next_path = extend_path(path, Field(key))
          rows.push(
            render_node(
              next_path,
              key,
              left_entries.get(key),
              right_entries.get(key),
              analysis,
              depth + 1.0,
            ),
          )
        }
      (Some(Json::Object(left_entries)), None) =>
        for key in object_keys(Some(left_entries), None) {
          let next_path = extend_path(path, Field(key))
          rows.push(
            render_node(
              next_path,
              key,
              left_entries.get(key),
              None,
              analysis,
              depth + 1.0,
            ),
          )
        }
      (None, Some(Json::Object(right_entries))) =>
        for key in object_keys(None, Some(right_entries)) {
          let next_path = extend_path(path, Field(key))
          rows.push(
            render_node(
              next_path,
              key,
              None,
              right_entries.get(key),
              analysis,
              depth + 1.0,
            ),
          )
        }
      (Some(Json::Array(left_items)), Some(Json::Array(right_items))) => {
        let total = if left_items.length() > right_items.length() {
          left_items.length()
        } else {
          right_items.length()
        }
        for idx = 0; idx < total; idx = idx + 1 {
          let next_path = extend_path(path, Index(idx))
          rows.push(
            render_node(
              next_path,
              "\{idx}",
              left_items.get(idx),
              right_items.get(idx),
              analysis,
              depth + 1.0,
              is_index=true,
            ),
          )
        }
      }
      (Some(Json::Array(left_items)), None) =>
        for idx = 0; idx < left_items.length(); idx = idx + 1 {
          let next_path = extend_path(path, Index(idx))
          rows.push(
            render_node(
              next_path,
              "\{idx}",
              left_items.get(idx),
              None,
              analysis,
              depth + 1.0,
              is_index=true,
            ),
          )
        }
      (None, Some(Json::Array(right_items))) =>
        for idx = 0; idx < right_items.length(); idx = idx + 1 {
          let next_path = extend_path(path, Index(idx))
          rows.push(
            render_node(
              next_path,
              "\{idx}",
              None,
              right_items.get(idx),
              analysis,
              depth + 1.0,
              is_index=true,
            ),
          )
        }
      _ => ()
    }
  }
  div(rows)
}

///|
fn view(store : Store) -> @respo_node.RespoNode[ActionOp, GlobalEvent] {
  let analysis = analyze_store(store)
  let is_diff_mode = store.mode == Diffing
  let on_left_input = fn(
    e : RespoEvent,
    dispatch : DispatchFn[ActionOp],
  ) -> Unit raise RespoCommonError {
    if e is Input(value~, ..) {
      dispatch.run(EditLeftDraft(value))
    }
  }
  let on_right_input = fn(
    e : RespoEvent,
    dispatch : DispatchFn[ActionOp],
  ) -> Unit raise RespoCommonError {
    if e is Input(value~, ..) {
      dispatch.run(EditRightDraft(value))
    }
  }
  div(
    class_name=@respo.ui_global,
    style=respo_style(
      padding_left=px(14),
      padding_right=px(14),
      padding_top=px(12),
      padding_bottom=px(12),
      background_color=color(210, 20, 97),
      height=vh(100),
      color=color(0, 0, 16),
    ),
    [
      div([
        div(
          style=respo_style(
            font_size=28,
            font_weight="700",
            font_family="Georgia, serif",
          ),
          [text_node("Structured JSON Diff")],
        ),
      ]),
      if !is_diff_mode {
        div(
          style=respo_style(
            display=display_flex,
            flex_direction=direction_row,
            gap=px(12),
            margin_top=px(12),
          ),
          [
            div(
              style=respo_style(
                width=pct(50),
                display=display_flex,
                flex_direction=direction_column,
                gap=px(8),
              ),
              [
                span(style=respo_style(font_weight="600"), [text_node("Left JSON")]),
                textarea(
                  class_name=@respo.ui_textarea,
                  value=store.draft_left,
                  placeholder="Paste the original JSON",
                  spellcheck=false,
                  style=respo_style(
                    width=pct(100),
                    height=px(236),
                    font_family="Menlo, Monaco, monospace",
                    font_size=12,
                  ),
                  on_input=on_left_input,
                ),
              ],
            ),
            div(
              style=respo_style(
                width=pct(50),
                display=display_flex,
                flex_direction=direction_column,
                gap=px(8),
              ),
              [
                span(style=respo_style(font_weight="600"), [text_node("Right JSON")]),
                textarea(
                  class_name=@respo.ui_textarea,
                  value=store.draft_right,
                  placeholder="Paste the updated JSON",
                  spellcheck=false,
                  style=respo_style(
                    width=pct(100),
                    height=px(236),
                    font_family="Menlo, Monaco, monospace",
                    font_size=12,
                  ),
                  on_input=on_right_input,
                ),
              ],
            ),
          ],
        )
      } else {
        div([])
      },
      div(
        style=respo_style(
          display=display_flex,
          flex_direction=direction_row,
          justify_content=justify_space_between,
          align_items=align_center,
          margin_top=px(10),
          padding_left=px(12),
          padding_right=px(12),
          padding_top=px(10),
          padding_bottom=px(10),
          background_color=color(0, 0, 100),
          border_radius=10.0,
        ),
        [
          div(
            style=respo_style(
              display=display_flex,
              flex_direction=direction_row,
              align_items=align_center,
              gap=px(8),
            ),
            [
              if is_diff_mode {
                button(
                  class_name=@respo.ui_button,
                  inner_text="Edit JSON",
                  on_click=(_e, dispatch) => dispatch.run(EditDrafts),
                )
              } else {
                button(
                  class_name=@respo.ui_button,
                  inner_text="Compare drafts",
                  on_click=(_e, dispatch) => dispatch.run(CompareDrafts),
                )
              },
              if is_diff_mode {
                button(
                  class_name=@respo.ui_button,
                  inner_text="Re-run compare",
                  on_click=(_e, dispatch) => dispatch.run(CompareDrafts),
                )
              } else {
                div([])
              },
            ],
          ),
          div([
            span(style=respo_style(font_size=12, color=color(0, 0, 45)), [
              text_node("\{analysis.patch_count} patches"),
            ]),
          ]),
        ],
      ),
      match analysis.left_error {
        Some(message) =>
          div(
            style=respo_style(
              margin_top=px(12),
              padding=px(12),
              background_color=color(4, 90, 94),
              color=color(2, 70, 32),
              border_radius=12.0,
            ),
            [text_node("Left JSON parse error: \{message}")],
          )
        None => div([])
      },
      match analysis.right_error {
        Some(message) =>
          div(
            style=respo_style(
              margin_top=px(12),
              padding=px(12),
              background_color=color(4, 90, 94),
              color=color(2, 70, 32),
              border_radius=12.0,
            ),
            [text_node("Right JSON parse error: \{message}")],
          )
        None => div([])
      },
      div(style=respo_style(margin_top=px(10)), [
        div(
          style=respo_style(
            display=display_flex,
            flex_direction=direction_column,
            gap=px(8),
          ),
          [
            match (analysis.left, analysis.right) {
              (Some(left), Some(right)) =>
                div(
                  style=respo_style(
                    background_color=color(0, 0, 100),
                    border_radius=12.0,
                    overflow=overflow_hidden,
                  ),
                  [
                    render_node(
                      [],
                      "root",
                      Some(left),
                      Some(right),
                      analysis,
                      0.0,
                    ),
                  ],
                )
              _ =>
                div(
                  style=respo_style(
                    padding=px(18),
                    background_color=color(0, 0, 100),
                    border_radius=12.0,
                    color=color(0, 0, 42),
                  ),
                  [
                    text_node(
                      "Fix JSON parse errors and click Compare drafts to render the structural diff.",
                    ),
                  ],
                )
            },
          ],
        ),
      ]),
    ],
  )
}

///|
fn main {
  let window = @dom_ffi.window()
  if window.document().query_selector(".app") is Some(mount_target) {
    let mount_target = mount_target.reinterpret_as_node()
    let app : @respo.RespoApp[Store] = {
      store: Ref(@respo.try_load_storage(app_store_key)),
      mount_target,
      storage_key: app_store_key,
    }
    app.backup_model_beforeunload()
    app.render_loop(() => view(app.store.val), op => {
      if !(op is StatesChange(_)) {
        @dom_ffi.log("Action: \{op}")
      }
      app.store.val = app.store.val.update(op)
    })
  } else {
    @dom_ffi.log("No mount target found")
  }
}
