import { ServicoRepository } from "../../infrastructure/repositories/servico.repository";
import type { CreateServicoDTO, UpdateServicoDTO } from "../dto/servico.dto";

export class ServicoService {
  private repo = new ServicoRepository();

  search(filters: {
    query?: string;
    includeInactive?: boolean;
    tipoServicoClinico?: string;
    page?: number;
    pageSize?: number;
  }) {
    return this.repo.search(filters);
  }

  getStats() {
    return this.repo.getStats();
  }

  async get(id: bigint) {
    const servico = await this.repo.findById(id);
    if (!servico) throw new Error("Serviço não encontrado");
    return servico;
  }

  async create(data: CreateServicoDTO, _userId: string) {
    const nome = data.nome.trim();
    await this.ensureUniqueName(nome);
    return this.repo.create({
      nome,
      tipoServicoClinico: data.tipoServicoClinico,
      preco: data.preco,
      ativo: data.ativo ?? true,
      taxRuleId: data.taxRuleId ? BigInt(data.taxRuleId) : null,
    });
  }

  async update(id: bigint, data: UpdateServicoDTO, _userId: string) {
    const existing = await this.repo.findById(id);
    if (!existing) throw new Error("Serviço não encontrado");

    if (data.nome !== undefined && data.nome.trim() !== existing.nome) {
      await this.ensureUniqueName(data.nome.trim(), id);
    }

    return this.repo.update(id, {
      ...(data.nome !== undefined ? { nome: data.nome.trim() } : {}),
      ...(data.tipoServicoClinico !== undefined
        ? { tipoServicoClinico: data.tipoServicoClinico }
        : {}),
      ...(data.preco !== undefined ? { preco: data.preco } : {}),
      ...(data.ativo !== undefined ? { ativo: data.ativo } : {}),
      ...(data.taxRuleId !== undefined
        ? { taxRuleId: data.taxRuleId ? BigInt(data.taxRuleId) : null }
        : {}),
    });
  }

  async delete(id: bigint, _userId: string) {
    const existing = await this.repo.findById(id);
    if (!existing) throw new Error("Serviço não encontrado");

    const linked = await this.repo.countLinkedInvoiceItems(id);
    if (linked > 0) {
      // Preserva histórico: desactiva em vez de apagar.
      return this.repo.softDeactivate(id);
    }

    return this.repo.softDeactivate(id);
  }

  private async ensureUniqueName(nome: string, ignoreId?: bigint) {
    const existing = await this.repo.findByNome(nome);
    if (existing && existing.id !== ignoreId) {
      throw new Error("Já existe um serviço com este nome");
    }
  }
}
