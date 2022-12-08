
<a name="0x0_task_store"></a>

# Module `0x0::task_store`



-  [Struct `Task`](#0x0_task_store_Task)
-  [Constants](#@Constants_0)
-  [Function `empty`](#0x0_task_store_empty)
-  [Function `add_task`](#0x0_task_store_add_task)
-  [Function `remove_task`](#0x0_task_store_remove_task)
-  [Function `get_task_reward`](#0x0_task_store_get_task_reward)


<pre><code><b>use</b> <a href="utils.md#0x0_utils">0x0::utils</a>;
<b>use</b> <a href="">0x1::string</a>;
<b>use</b> <a href="">0x2::object</a>;
<b>use</b> <a href="">0x2::tx_context</a>;
<b>use</b> <a href="">0x2::vec_map</a>;
</code></pre>



<a name="0x0_task_store_Task"></a>

## Struct `Task`



<pre><code><b>struct</b> <a href="task_store.md#0x0_task_store_Task">Task</a> <b>has</b> drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>id: <a href="_ID">object::ID</a></code>
</dt>
<dd>

</dd>
<dt>
<code>name: <a href="_String">string::String</a></code>
</dt>
<dd>

</dd>
<dt>
<code>description: <a href="_String">string::String</a></code>
</dt>
<dd>

</dd>
<dt>
<code>reward_exp: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>package_id: <a href="_ID">object::ID</a></code>
</dt>
<dd>

</dd>
<dt>
<code>module_name: <a href="_String">string::String</a></code>
</dt>
<dd>

</dd>
<dt>
<code>function_name: <a href="_String">string::String</a></code>
</dt>
<dd>

</dd>
<dt>
<code>arguments: <a href="">vector</a>&lt;<a href="_String">string::String</a>&gt;</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="0x0_task_store_INITIAL_XP"></a>



<pre><code><b>const</b> <a href="task_store.md#0x0_task_store_INITIAL_XP">INITIAL_XP</a>: u64 = 0;
</code></pre>



<a name="0x0_task_store_BASIC_REWARD_XP"></a>



<pre><code><b>const</b> <a href="task_store.md#0x0_task_store_BASIC_REWARD_XP">BASIC_REWARD_XP</a>: u64 = 5;
</code></pre>



<a name="0x0_task_store_EMaxTasksReached"></a>



<pre><code><b>const</b> <a href="task_store.md#0x0_task_store_EMaxTasksReached">EMaxTasksReached</a>: u64 = 0;
</code></pre>



<a name="0x0_task_store_MAX_TASKS"></a>



<pre><code><b>const</b> <a href="task_store.md#0x0_task_store_MAX_TASKS">MAX_TASKS</a>: u64 = 100;
</code></pre>



<a name="0x0_task_store_empty"></a>

## Function `empty`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="task_store.md#0x0_task_store_empty">empty</a>(): <a href="_VecMap">vec_map::VecMap</a>&lt;<a href="_ID">object::ID</a>, <a href="task_store.md#0x0_task_store_Task">task_store::Task</a>&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="task_store.md#0x0_task_store_empty">empty</a>(): VecMap&lt;ID, <a href="task_store.md#0x0_task_store_Task">Task</a>&gt; {
    <a href="_empty">vec_map::empty</a>&lt;ID, <a href="task_store.md#0x0_task_store_Task">Task</a>&gt;()
}
</code></pre>



</details>

<a name="0x0_task_store_add_task"></a>

## Function `add_task`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="task_store.md#0x0_task_store_add_task">add_task</a>(store: &<b>mut</b> <a href="_VecMap">vec_map::VecMap</a>&lt;<a href="_ID">object::ID</a>, <a href="task_store.md#0x0_task_store_Task">task_store::Task</a>&gt;, name: <a href="">vector</a>&lt;u8&gt;, description: <a href="">vector</a>&lt;u8&gt;, reward_exp: u64, package_id: <a href="_ID">object::ID</a>, module_name: <a href="">vector</a>&lt;u8&gt;, function_name: <a href="">vector</a>&lt;u8&gt;, arguments: <a href="">vector</a>&lt;<a href="">vector</a>&lt;u8&gt;&gt;, ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="task_store.md#0x0_task_store_add_task">add_task</a>(
    store: &<b>mut</b> VecMap&lt;ID, <a href="task_store.md#0x0_task_store_Task">Task</a>&gt;,
    name: <a href="">vector</a>&lt;u8&gt;,
    description: <a href="">vector</a>&lt;u8&gt;,
    reward_exp: u64,
    package_id: ID,
    module_name: <a href="">vector</a>&lt;u8&gt;,
    function_name: <a href="">vector</a>&lt;u8&gt;,
    arguments: <a href="">vector</a>&lt;<a href="">vector</a>&lt;u8&gt;&gt;,
    ctx: &<b>mut</b> TxContext
) {
    <b>assert</b>!(<a href="_size">vec_map::size</a>(store) &lt;= <a href="task_store.md#0x0_task_store_MAX_TASKS">MAX_TASKS</a>, <a href="task_store.md#0x0_task_store_EMaxTasksReached">EMaxTasksReached</a>);

    <b>let</b> uid = <a href="_new">object::new</a>(ctx);
    <b>let</b> id = <a href="_uid_to_inner">object::uid_to_inner</a>(&uid);
    <a href="_delete">object::delete</a>(uid);

    <b>let</b> task = <a href="task_store.md#0x0_task_store_Task">Task</a> {
        id,
        name: <a href="_utf8">string::utf8</a>(name),
        description: <a href="_utf8">string::utf8</a>(description),
        reward_exp,
        package_id,
        module_name: <a href="_utf8">string::utf8</a>(module_name),
        function_name: <a href="_utf8">string::utf8</a>(function_name),
        arguments: <a href="utils.md#0x0_utils_to_string_vec">utils::to_string_vec</a>(arguments),
    };
    <a href="_insert">vec_map::insert</a>(store, id, task);
}
</code></pre>



</details>

<a name="0x0_task_store_remove_task"></a>

## Function `remove_task`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="task_store.md#0x0_task_store_remove_task">remove_task</a>(store: &<b>mut</b> <a href="_VecMap">vec_map::VecMap</a>&lt;<a href="_ID">object::ID</a>, <a href="task_store.md#0x0_task_store_Task">task_store::Task</a>&gt;, task_id: <a href="_ID">object::ID</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="task_store.md#0x0_task_store_remove_task">remove_task</a>(store: &<b>mut</b> VecMap&lt;ID, <a href="task_store.md#0x0_task_store_Task">Task</a>&gt;, task_id: ID) {
    <a href="_remove">vec_map::remove</a>(store, &task_id);
}
</code></pre>



</details>

<a name="0x0_task_store_get_task_reward"></a>

## Function `get_task_reward`



<pre><code><b>public</b> <b>fun</b> <a href="task_store.md#0x0_task_store_get_task_reward">get_task_reward</a>(store: &<a href="_VecMap">vec_map::VecMap</a>&lt;<a href="_ID">object::ID</a>, <a href="task_store.md#0x0_task_store_Task">task_store::Task</a>&gt;, task_id: &<a href="_ID">object::ID</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="task_store.md#0x0_task_store_get_task_reward">get_task_reward</a>(store: &VecMap&lt;ID, <a href="task_store.md#0x0_task_store_Task">Task</a>&gt;, task_id: &ID): u64 {
   <a href="_get">vec_map::get</a>(store, task_id).reward_exp
}
</code></pre>



</details>
