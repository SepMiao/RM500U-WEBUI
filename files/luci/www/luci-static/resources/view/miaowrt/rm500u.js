'use strict';
'require view';
'require rpc';

const getStatus = rpc.declare({ object: 'miaowrt.rm500u', method: 'status', reject: true });

function isLoopback(host) {
	return host === 'localhost' || host === '[::1]' || host.startsWith('127.');
}

function consoleURL(listen) {
	const urls = [];

	for (const entry of listen.split(';')) {
		try {
			const url = new URL(entry.trim());
			if (!['http:', 'https:'].includes(url.protocol) || url.username || url.password ||
			    url.pathname !== '/' || url.search || url.hash)
				continue;

			const host = url.hostname;
			if (isLoopback(host)) {
				if (!isLoopback(window.location.hostname))
					continue;
			}
			else if (host === '0.0.0.0' || host === '[::]' ||
			         (!host.startsWith('[') && !/^\d+\.\d+\.\d+\.\d+$/.test(host))) {
				// Kestrel treats host names other than localhost as wildcard bindings.
				url.hostname = window.location.hostname;
			}

			urls.push(url);
		}
		catch (err) {
			continue;
		}
	}

	return urls.find(url => url.protocol === window.location.protocol) || urls[0];
}

return view.extend({
	load: function() {
		return getStatus();
	},

	render: function(status) {
		const state = status.running ? '运行中' : (status.enabled ? '已停止' : '已禁用');
		const url = consoleURL(status.listen);
		const content = [
			E('h2', {}, 'RM500U 控制台'),
			E('div', { 'class': 'cbi-section' }, [
				E('h3', {}, '服务状态'),
				E('p', {}, [state, ' · ', status.simulate ? '模拟模式' : '硬件模式']),
				E('p', {}, ['监听地址　', E('code', {}, [status.listen])])
			])
		];

		if (!status.running)
			content.push(E('p', {}, '服务启动后，刷新本页即可进入控制台。'));
		else if (!url)
			content.push(E('p', {}, '请将服务监听地址设为浏览器可访问的 HTTP 或 HTTPS 地址。'));
		else {
			content.push(E('p', {}, [
				E('a', {
					'class': 'cbi-button cbi-button-action', href: url.href,
					target: '_blank', rel: 'noopener noreferrer'
				}, '在新标签页打开控制台')
			]));

			if (window.location.protocol === 'https:' && url.protocol === 'http:')
				content.push(E('p', {}, '当前 LuCI 使用 HTTPS，请在新标签页打开 HTTP 控制台。'));
			else {
				content.push(E('p', {}, '首次登录请使用控制台账号。如果浏览器未弹出登录框，请先在新标签页登录，再刷新本页。'));
				content.push(E('iframe', {
					src: url.href, title: 'RM500U 模组管理',
					style: 'display:block; width:100%; height:78vh; border:0'
				}));
			}
		}

		return E('div', {}, content);
	},

	handleSaveApply: null,
	handleSave: null,
	handleReset: null
});
