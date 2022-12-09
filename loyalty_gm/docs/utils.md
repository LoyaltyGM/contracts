
<a name="0x0_utils"></a>

# Module `0x0::utils`



-  [Function `to_string_vec`](#0x0_utils_to_string_vec)


<pre><code><b>use</b> <a href="">0x1::string</a>;
<b>use</b> <a href="">0x1::vector</a>;
</code></pre>



<a name="0x0_utils_to_string_vec"></a>

## Function `to_string_vec`


Converts a vector of u8 vectors to a vector of strings



<pre><code><b>public</b> <b>fun</b> <a href="utils.md#0x0_utils_to_string_vec">to_string_vec</a>(args: <a href="">vector</a>&lt;<a href="">vector</a>&lt;u8&gt;&gt;): <a href="">vector</a>&lt;<a href="_String">string::String</a>&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="utils.md#0x0_utils_to_string_vec">to_string_vec</a>(args: <a href="">vector</a>&lt;<a href="">vector</a>&lt;u8&gt;&gt;): <a href="">vector</a>&lt;String&gt; {
    <b>let</b> string_args = <a href="_empty">vector::empty</a>&lt;String&gt;();
    <a href="_reverse">vector::reverse</a>(&<b>mut</b> args);

    <b>while</b>(!<a href="_is_empty">vector::is_empty</a>(&args)) {
        <a href="_push_back">vector::push_back</a>(&<b>mut</b> string_args, <a href="_utf8">string::utf8</a>(<a href="_pop_back">vector::pop_back</a>(&<b>mut</b> args)))
    };

    string_args
}
</code></pre>



</details>
